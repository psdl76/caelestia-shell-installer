#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$ROOT_DIR/lib"
APP_DEF_DIR="$ROOT_DIR/apps"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/app_definitions.sh"
source "$LIB_DIR/ownership.sh"
source "$LIB_DIR/locking.sh"
source "$LIB_DIR/app_schema.sh"
source "$LIB_DIR/hyprland_live.sh"
trap on_error ERR

[[ $# -eq 1 ]] || { echo "Verwendung: $0 <app-id>"; exit 2; }
APP_ID_REQUESTED="$1"
APP_DEF="$(find_app_definition "$APP_ID_REQUESTED" || true)"
[[ -n "$APP_DEF" && -f "$APP_DEF" ]] || die "Unbekannte App-Definition: $APP_ID_REQUESTED"
validate_app_schema_source "$APP_DEF"
# shellcheck disable=SC1090
source "$APP_DEF"
apply_app_category_defaults

acquire_mutation_lock "uninstall:$APP_ID"

STATE_ROOT="$HOME/.local/state/caelestia-webapps"
LOG_DIR="$STATE_ROOT/logs"
BACKUP_DIR="$STATE_ROOT/backups/$APP_ID"
LOG_FILE="$LOG_DIR/$APP_ID-uninstall.log"
DATA_ROOT="$HOME/.local/share/caelestia-webapps"
APP_DATA_DIR="$DATA_ROOT/apps/$APP_ID"
BIN_DIR="$HOME/.local/bin"
LAUNCHER="$BIN_DIR/caelestia-webapp-$APP_ID"
SETUP_LAUNCHER="$BIN_DIR/caelestia-webapp-$APP_ID-setup"
APPLICATIONS_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/caelestia-webapp-$APP_ID.desktop"
ICON_ROOT="$HOME/.local/share/icons/hicolor"
ICON_DIR="$ICON_ROOT/scalable/apps"
ICON_FILE="$ICON_DIR/$ICON_NAME.svg"
HYPR_RULES_FILE="$HOME/.config/hypr/hyprland/rules.lua"
HYPR_KEYBINDS_FILE="$HOME/.config/hypr/hyprland/keybinds.lua"
CATALOG_FILE="$DATA_ROOT/catalog.json"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1
source "$LIB_DIR/catalog.sh"
source "$LIB_DIR/uninstall_infrastructure.sh"

TX_DIR="$(mktemp -d)" || die "Temporäres Uninstall-Verzeichnis konnte nicht erstellt werden."
trap 'rm -rf -- "$TX_DIR"' EXIT
ORIG_RULES="$TX_DIR/rules.original.lua"
ORIG_KEYBINDS="$TX_DIR/keybinds.original.lua"
TMP_RULES="$TX_DIR/rules.lua"
TMP_KEYBINDS="$TX_DIR/keybinds.lua"
RULES_CHANGED=false
KEYBINDS_CHANGED=false
SHARED_RUNTIME_REMOVED=false

if [[ -f "$HYPR_RULES_FILE" ]]; then
    cp -- "$HYPR_RULES_FILE" "$ORIG_RULES"
    cp -- "$ORIG_RULES" "$TMP_RULES"
fi
if [[ -f "$HYPR_KEYBINDS_FILE" ]]; then
    cp -- "$HYPR_KEYBINDS_FILE" "$ORIG_KEYBINDS"
    cp -- "$ORIG_KEYBINDS" "$TMP_KEYBINDS"
fi

step "$APP_NAME deinstallieren"

# ---------------------------------------------------------------------------
# Phase A: complete all risky configuration work on temporary copies.
# Nothing user-visible is removed before this phase validates successfully.
# ---------------------------------------------------------------------------
step "Deinstallation vorbereiten"

if [[ -f "$TMP_RULES" && "${USE_OPAQUE_TAG:-false}" == "true" ]]; then
    if remove_app_line_from_tagged_rule_tmp "$TMP_RULES" "opaque_tag" "$WINDOW_CLASS" opaque; then
        RULES_CHANGED=true
        ok "App-spezifische opaque-Regel vorbereitet"
    else
        info "Keine app-spezifische opaque-Regel gefunden"
    fi
fi

if [[ -f "$TMP_RULES" && -n "${HYPR_SHARED_TAG:-}" ]]; then
    if remove_app_line_from_tagged_rule_tmp "$TMP_RULES" "$HYPR_SHARED_TAG" "$WINDOW_CLASS" shared; then
        RULES_CHANGED=true
        ok "$APP_NAME aus $HYPR_SHARED_TAG vorbereitet"
    else
        info "$APP_NAME ist nicht in $HYPR_SHARED_TAG eingetragen"
    fi

    # Remove shared infrastructure only when it is WebApps-owned AND no other
    # installed app still consumes the same tag. Native Caelestia structures
    # (e.g. communication_app_tag) are never removed by this project.
    if [[ "${HYPR_SHARED_OWNER:-}" == "caelestia-webapps" ]] \
       && ! other_installed_app_uses_shared_tag "$HYPR_SHARED_TAG"; then
        SHARED_RUNTIME_REMOVED=true
        info "Keine weitere WebApp benötigt $HYPR_SHARED_TAG"
        if remove_project_owned_tagged_rule_tmp "$TMP_RULES" "$HYPR_SHARED_TAG" "${HYPR_SHARED_RULE_MARKER:-}"; then RULES_CHANGED=true; fi
        if remove_exact_managed_line_from_tmp "$TMP_RULES" "${HYPR_SHARED_CREATE_TAG:-}"; then RULES_CHANGED=true; fi
        if remove_exact_managed_line_from_tmp "$TMP_RULES" "${HYPR_SHARED_LOCAL_DECL:-}"; then RULES_CHANGED=true; fi
        if [[ -f "$TMP_KEYBINDS" && -n "${HYPR_SHARED_KEYBIND:-}" ]]; then
            if remove_exact_managed_line_from_tmp "$TMP_KEYBINDS" "$HYPR_SHARED_KEYBIND"; then KEYBINDS_CHANGED=true; fi
        fi
        ok "Nicht mehr benötigte WebApps-Infrastruktur für ${HYPR_SHARED_WORKSPACE:-$HYPR_SHARED_TAG} vorbereitet"
    fi
fi


step "Temporäre Konfiguration validieren"
[[ ! -f "$TMP_RULES" || -s "$TMP_RULES" ]] || die "Temporäre rules.lua ist leer."
[[ ! -f "$TMP_KEYBINDS" || -s "$TMP_KEYBINDS" ]] || die "Temporäre keybinds.lua ist leer."
if command -v luac >/dev/null 2>&1; then
    [[ "$RULES_CHANGED" != true ]] || luac -p "$TMP_RULES" || die "Temporäre rules.lua enthält ungültige Lua-Syntax."
    [[ "$KEYBINDS_CHANGED" != true ]] || luac -p "$TMP_KEYBINDS" || die "Temporäre keybinds.lua enthält ungültige Lua-Syntax."
fi
ok "Temporäre Deinstallationskonfiguration geprüft"

# ---------------------------------------------------------------------------
# Phase B: commit the validated configuration once, with exactly one backup
# per changed live file. Current Lua sessions receive targeted runtime updates;
# older configurations retain the validated full-reload fallback.
# ---------------------------------------------------------------------------
step "Validierte Hyprland-Änderungen übernehmen"
restore_uninstall_originals() {
    local failed=false
    if [[ "$RULES_CHANGED" == true ]] && ! atomic_replace_file "$ORIG_RULES" "$HYPR_RULES_FILE" 644; then failed=true; fi
    if [[ "$KEYBINDS_CHANGED" == true ]] && ! atomic_replace_file "$ORIG_KEYBINDS" "$HYPR_KEYBINDS_FILE" 644; then failed=true; fi
    [[ "$failed" == false ]]
}

LUA_LIVE=false
if [[ "$RULES_CHANGED" == true || "$KEYBINDS_CHANGED" == true ]] && hypr_lua_live_begin; then
    LUA_LIVE=true
    info "Hyprland-Lua-Regeln werden ohne vollständigen Konfigurationsreload entfernt"
fi
# Abort immediately before touching either live file if a user or another
# process changed the configuration while the transaction was being prepared.
if [[ "$RULES_CHANGED" == true ]] && ! cmp -s -- "$ORIG_RULES" "$HYPR_RULES_FILE"; then
    [[ "$LUA_LIVE" == true ]] && hypr_lua_live_finish || true
    die "rules.lua wurde während der Deinstallation extern verändert; Commit abgebrochen."
fi
if [[ "$KEYBINDS_CHANGED" == true ]] && ! cmp -s -- "$ORIG_KEYBINDS" "$HYPR_KEYBINDS_FILE"; then
    [[ "$LUA_LIVE" == true ]] && hypr_lua_live_finish || true
    die "keybinds.lua wurde während der Deinstallation extern verändert; Commit abgebrochen."
fi
if [[ "$RULES_CHANGED" == true ]]; then
    backup_file "$HYPR_RULES_FILE"
    if ! atomic_replace_file "$TMP_RULES" "$HYPR_RULES_FILE" 644; then
        [[ "$LUA_LIVE" == true ]] && hypr_lua_live_finish || true
        die "rules.lua konnte nicht aktualisiert werden."
    fi
    ok "rules.lua aktualisiert"
fi
if [[ "$KEYBINDS_CHANGED" == true ]]; then
    backup_file "$HYPR_KEYBINDS_FILE"
    if ! atomic_replace_file "$TMP_KEYBINDS" "$HYPR_KEYBINDS_FILE" 644; then
        restore_uninstall_originals || true
        [[ "$LUA_LIVE" == true ]] && hypr_lua_live_finish || true
        die "keybinds.lua konnte nicht aktualisiert werden."
    fi
    ok "keybinds.lua aktualisiert"
fi

if [[ "$RULES_CHANGED" == true || "$KEYBINDS_CHANGED" == true ]]; then
    if [[ "$LUA_LIVE" == true ]]; then
        hypr_lua_disable_app_rules
        [[ "$SHARED_RUNTIME_REMOVED" == true ]] && hypr_lua_disable_project_shared_runtime
        hypr_lua_live_finish || die "Hyprland-Autoreload konnte nicht sicher wiederhergestellt werden."
        ok "Hyprland-Regeln ohne Monitor-Reload entfernt"
    elif command -v hyprctl >/dev/null 2>&1; then
        if ! hyprctl reload >/dev/null; then
            restore_uninstall_originals || true
            hyprctl reload >/dev/null 2>&1 || true
            die "hyprctl reload ist fehlgeschlagen; ursprüngliche Konfiguration wurde wiederhergestellt."
        fi
        errors="$(hyprctl configerrors 2>&1 || true)"
        if [[ -n "$errors" && "$errors" != "no errors" && "$errors" != *"No errors"* ]]; then
            echo "$errors"
            restore_uninstall_originals || true
            hyprctl reload >/dev/null 2>&1 || true
            die "Hyprland meldet Konfigurationsfehler; ursprüngliche Konfiguration wurde wiederhergestellt."
        fi
        ok "Hyprland neu geladen"
    else
        warn "hyprctl nicht gefunden; Hyprland wurde nicht neu geladen."
    fi
else
    info "Keine Hyprland-Datei musste geändert werden"
fi

# ---------------------------------------------------------------------------
# Phase C: remove only artifacts owned by this app.
# ---------------------------------------------------------------------------
step "Web-App-Dateien entfernen"
remove_managed_file() {
    local file="$1"
    if [[ -e "$file" ]]; then
        rm -f -- "$file" || die "Datei konnte nicht entfernt werden: $file"
        ok "Entfernt: $file"
    else
        info "Nicht vorhanden: $file"
    fi
}
remove_managed_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        rm -rf -- "$dir" || die "Verzeichnis konnte nicht entfernt werden: $dir"
        ok "Entfernt: $dir"
    else
        info "Nicht vorhanden: $dir"
    fi
}
remove_managed_file "$LAUNCHER"
remove_managed_file "$SETUP_LAUNCHER"
remove_managed_file "$DESKTOP_FILE"
if other_installed_app_uses_icon "$ICON_NAME"; then
    info "Icon $ICON_NAME wird noch von einer anderen WebApp verwendet"
else
    remove_managed_file "$ICON_FILE"
fi
remove_managed_dir "$APP_DATA_DIR"

step "Katalog und Applet Registry aktualisieren"
generate_catalog
ok "Runtime-Metadaten aktualisiert"


step "Caches aktualisieren"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache --force --ignore-theme-index "$ICON_ROOT" >/dev/null 2>&1 || true
ok "Caches aktualisiert"

# Phase 16.5 contract: after a successful uninstall an explicit applet
# activation override must not remain enabled. Capability preferences are
# intentionally preserved for a later reinstall. The CLI stores this state
# below XDG_STATE_HOME (falling back to ~/.local/state), so use the same root.
APPLET_STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia-webapps"
APPLET_STATE_FILE="$APPLET_STATE_ROOT/applets.json"
if [[ -f "$APPLET_STATE_FILE" ]]; then
    python3 - "$APPLET_STATE_FILE" "$APP_ID" <<'PY_APPLET_RESET'
import json
import os
import sys
import tempfile
from pathlib import Path

path = Path(sys.argv[1])
app_id = sys.argv[2]
try:
    payload = json.loads(path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError):
    raise SystemExit(0)

if not isinstance(payload, dict) or payload.get("schemaVersion", 1) != 1:
    raise SystemExit(0)
enabled = payload.get("enabled")
if not isinstance(enabled, dict) or app_id not in enabled or enabled.get(app_id) is False:
    raise SystemExit(0)

enabled[app_id] = False
payload = {"schemaVersion": 1, "enabled": enabled}
path.parent.mkdir(parents=True, exist_ok=True)
fd, tmp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(tmp_name, path)
finally:
    try:
        os.unlink(tmp_name)
    except FileNotFoundError:
        pass
PY_APPLET_RESET
fi

echo
echo -e "${GREEN}${BOLD}$APP_NAME wurde deinstalliert.${RESET}"
echo "Backups bleiben erhalten unter: $BACKUP_DIR"
