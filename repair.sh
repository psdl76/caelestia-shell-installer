#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DEF_DIR="$ROOT_DIR/apps"
DATA_ROOT="$HOME/.local/share/caelestia-webapps"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia-webapps"
LOG_DIR="$STATE_ROOT/logs"
LOG_FILE="$LOG_DIR/repair.log"
CURRENT_VERSION="$(<"$ROOT_DIR/VERSION")"
LIB_DIR="$ROOT_DIR/lib"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

usage() {
    cat <<USAGE
Verwendung: $0 [--dry-run] [--app <app-id>] [--preflight] [--quiet]

Repariert/migriert vorhandene Caelestia WebApps auf Paketversion $CURRENT_VERSION.
Ohne --app werden alle erkannten installierten Apps verarbeitet.
USAGE
}

DRY_RUN=false
PREFLIGHT=false
QUIET=false
ONLY_APP=""
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=true ;;
        --preflight) PREFLIGHT=true ;;
        --quiet) QUIET=true ;;
        --app)
            shift
            [[ $# -gt 0 ]] || { usage >&2; exit 2; }
            ONLY_APP="$1"
            ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unbekannte Option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if $QUIET; then
    exec >>"$LOG_FILE" 2>&1
else
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

source "$LIB_DIR/common.sh"
source "$LIB_DIR/app_definitions.sh"
source "$LIB_DIR/ownership.sh"
source "$LIB_DIR/locking.sh"
source "$LIB_DIR/catalog.sh"

STATE_MIGRATOR="$ROOT_DIR/scripts/migrate_runtime_state.py"
STATE_MIGRATION_REPORT="$STATE_ROOT/runtime-state-migration-last.json"

acquire_mutation_lock "repair${ONLY_APP:+:$ONLY_APP}"
assert_no_shadowing || exit 2
trap on_error ERR

# Phase 16.2 repair gate: package definitions must satisfy the frozen catalog
# contract before any installed app is modified.
if ! python3 "$ROOT_DIR/scripts/validate_definitions.py" "$ROOT_DIR" >"$STATE_ROOT/catalog-contract-last.json"; then
    echo "Catalog-Contract verletzt; Repair wurde vor Änderungen abgebrochen." >&2
    echo "Details: $STATE_ROOT/catalog-contract-last.json" >&2
    exit 2
fi

is_known_app() {
    find_app_definition "$1" >/dev/null
}

app_has_existing_state() {
    local id="$1"
    [[ -f "$DATA_ROOT/apps/$id/installed.conf" \
       || -d "$DATA_ROOT/apps/$id/profile" \
       || -x "$HOME/.local/bin/caelestia-webapp-$id" \
       || -f "$HOME/.local/share/applications/caelestia-webapp-$id.desktop" ]]
}

installed_version_for() {
    local id="$1" meta="$DATA_ROOT/apps/$id/installed.conf"
    if [[ -f "$meta" ]]; then
        awk -F= '/^INSTALLER_VERSION=/{gsub(/^"|"$/, "", $2); print $2; exit}' "$meta"
    fi
}

mapfile -t KNOWN_APPS < <(list_app_ids)
TARGETS=()

if [[ -n "$ONLY_APP" ]]; then
    is_known_app "$ONLY_APP" || { echo "Unbekannte App-ID: $ONLY_APP" >&2; exit 2; }
    app_has_existing_state "$ONLY_APP" || {
        echo "Keine vorhandene Installation für $ONLY_APP erkannt." >&2
        exit 1
    }
    TARGETS+=("$ONLY_APP")
else
    for id in "${KNOWN_APPS[@]}"; do
        app_has_existing_state "$id" && TARGETS+=("$id")
    done
fi

# Cheap manager preflight. Only enter the full tested repair path when package
# state is stale or generated entry points are missing.
if $PREFLIGHT; then
    preflight_needed=false
    last_repaired=""
    [[ -f "$STATE_ROOT/last-repaired-version" ]] && last_repaired="$(<"$STATE_ROOT/last-repaired-version")"
    [[ "$last_repaired" == "$CURRENT_VERSION" ]] || preflight_needed=true

    for id in "${TARGETS[@]}"; do
        [[ "$(installed_version_for "$id")" == "$CURRENT_VERSION" ]] || preflight_needed=true
        [[ -x "$HOME/.local/bin/caelestia-webapp-$id" ]] || preflight_needed=true
        [[ -x "$HOME/.local/bin/caelestia-webapp-$id-setup" ]] || preflight_needed=true
        [[ -f "$HOME/.local/share/applications/caelestia-webapp-$id.desktop" ]] || preflight_needed=true
    done

    # The migrator uses exit 10 as an expected "migration required" signal.
    # Keep the command in an if-condition so the global ERR trap does not
    # mistake that contract result for an unexpected repair failure.
    if python3 "$STATE_MIGRATOR" --state-root "$STATE_ROOT" --check --json >"$STATE_MIGRATION_REPORT"; then
        state_check_rc=0
    else
        state_check_rc=$?
    fi
    case "$state_check_rc" in
        0) ;;
        10) preflight_needed=true ;;
        *) echo "Runtime-State-Preflight ist fehlgeschlagen; Details: $STATE_MIGRATION_REPORT" >&2; exit 2 ;;
    esac

    if ! $preflight_needed; then
        echo "Preflight: installierter Zustand ist aktuell ($CURRENT_VERSION)."
        exit 0
    fi
    echo "Preflight: Self-Heal auf Paketversion $CURRENT_VERSION erforderlich."
fi

cat <<EOF_BANNER

╭────────────────────────────────────────────────────────╮
│           Caelestia WebApps Repair / Upgrade           │
╰────────────────────────────────────────────────────────╯

Paketversion : $CURRENT_VERSION
Erkannte Apps: ${#TARGETS[@]}
Log          : $LOG_FILE
EOF_BANNER

if ((${#TARGETS[@]} == 0)); then
    echo
    echo "Keine bekannte installierte WebApp gefunden."
    if ! $DRY_RUN; then
        step "Katalog und Applet Registry aktualisieren"
        generate_catalog
        step "Applet Runtime-State migrieren"
        python3 "$STATE_MIGRATOR" --state-root "$STATE_ROOT" --json >"$STATE_MIGRATION_REPORT"
        ok "Runtime-State geprüft/migriert"
    fi
    exit 0
fi

echo
for id in "${TARGETS[@]}"; do
    old="$(installed_version_for "$id")"
    [[ -n "$old" ]] || old="vor Versionsmetadaten"
    printf '  %-18s %s -> %s\n' "$id" "$old" "$CURRENT_VERSION"
done

if $DRY_RUN; then
    echo
    echo "Dry-Run: Es wurden keine Dateien verändert."
    exit 0
fi

FAILED=()
for id in "${TARGETS[@]}"; do
    echo
    echo "============================================================"
    echo "Repair/Upgrade: $id"
    echo "============================================================"
    if "$ROOT_DIR/install.sh" "$id" --no-applet; then
        :
    else
        FAILED+=("$id")
        warn "$id konnte nicht repariert werden; Details stehen im App-Log und in $LOG_FILE"
    fi
done

# UI integrations are intentionally outside the engine core.

step "Katalog und Applet Registry abschließend synchronisieren"
generate_catalog

step "Applet Runtime-State migrieren"
python3 "$STATE_MIGRATOR" --state-root "$STATE_ROOT" --json >"$STATE_MIGRATION_REPORT"
ok "Runtime-State geprüft/migriert"

if ((${#FAILED[@]} > 0)); then
    echo
    error_context "$DATA_ROOT" "Fehlgeschlagene Apps können einzeln erneut mit ./repair.sh --app <app-id> repariert werden."
    die "Repair/Upgrade unvollständig. Fehlgeschlagen: ${FAILED[*]}"
fi

echo
printf '%s\n' "$CURRENT_VERSION" > "$STATE_ROOT/last-repaired-version"
echo "╭────────────────────────────────────────────────────────╮"
echo "│             REPAIR / UPGRADE ERFOLGREICH              │"
echo "╰────────────────────────────────────────────────────────╯"
echo "Alle erkannten Apps entsprechen jetzt Paketversion $CURRENT_VERSION."
echo "Log: $LOG_FILE"
