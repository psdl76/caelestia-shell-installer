#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DEF_DIR="$ROOT_DIR/apps"
source "$ROOT_DIR/lib/app_definitions.sh"
source "$ROOT_DIR/lib/ownership.sh"
source "$ROOT_DIR/lib/locking.sh"
DATA_ROOT="$HOME/.local/share/caelestia-webapps"
CATALOG_FILE="$DATA_ROOT/catalog.json"
APPLET_REGISTRY_FILE="$DATA_ROOT/applet-registry.json"
mkdir -p "$DATA_ROOT"


validate_all_apps() {
    local failed=0 conf requested
    source "$ROOT_DIR/lib/common.sh"
    source "$ROOT_DIR/lib/app_schema.sh"
    echo "App-Definitionen prüfen"
    echo "------------------------------------------------------------"
    shopt -s nullglob
    for conf in "$APP_DEF_DIR"/*.conf "$USER_APP_DEF_DIR"/*.conf; do
        [[ -f "$conf" ]] || continue
        requested="$(basename "$conf" .conf)"
        # Each definition is validated in a subshell so values cannot leak into
        # the next app definition.
        if (
            validate_app_schema_source "$conf"
            # shellcheck disable=SC1090
            source "$conf"
            apply_app_category_defaults
            BACKUP_DIR="${TMPDIR:-/tmp}"
            validate_app_definition
            [[ "$requested" == "$APP_ID" ]] || die "Dateiname und APP_ID stimmen nicht überein: $requested != $APP_ID"
        ); then
            :
        else
            echo "✗ $requested"
            failed=1
        fi
    done
    if [[ "$failed" -eq 0 ]]; then
        python3 "$ROOT_DIR/scripts/validate_definitions.py" "$ROOT_DIR" >/dev/null || failed=1
    fi
    [[ "$failed" -eq 0 ]] && echo "✓ Alle App-Definitionen entsprechen dem zentralen Schema + Phase-16.2-Contract"
    return "$failed"
}

rebuild_catalog() {
    source "$ROOT_DIR/lib/common.sh"
    source "$ROOT_DIR/lib/catalog.sh"
    generate_catalog >&2
}


check_streaming_icons() {
    local failed=0 conf app_id app_name category icon_url local_file tmp
    command -v curl >/dev/null 2>&1 || { echo "curl fehlt (sudo pacman -S curl)" >&2; return 1; }
    echo "Streaming-Iconquellen prüfen"
    echo "------------------------------------------------------------"
    shopt -s nullglob
    for conf in "$APP_DEF_DIR"/*.conf "$USER_APP_DEF_DIR"/*.conf; do
        [[ -f "$conf" ]] || continue
        local data rc
        data="$(
            source "$ROOT_DIR/lib/common.sh"
            source "$ROOT_DIR/lib/app_schema.sh"
            validate_app_schema_source "$conf" >/dev/null
            # shellcheck disable=SC1090
            source "$conf"
            apply_app_category_defaults >/dev/null
            [[ "${APP_CATALOG_CATEGORY:-}" == "streaming" ]] || exit 10
            printf '%s\n%s\n%s\n%s\n' "$APP_ID" "$APP_NAME" "${ICON_URL:-}" "${ICON_LOCAL_FILE:-}"
        )" || {
            rc=$?; [[ $rc -eq 10 ]] && continue
            echo "✗ Konfiguration konnte nicht gelesen werden: $conf"
            failed=1; continue
        }
        mapfile -t _icon_fields <<< "$data"
        app_id="${_icon_fields[0]:-}"
        app_name="${_icon_fields[1]:-}"
        icon_url="${_icon_fields[2]:-}"
        local_file="${_icon_fields[3]:-}"
        if [[ -n "$icon_url" ]]; then
            tmp="$(mktemp)"
            if curl --fail --location --silent --show-error --connect-timeout 10 --max-time 30 "$icon_url" -o "$tmp" \
               && [[ -s "$tmp" ]] && grep -qi '<svg' "$tmp"; then
                echo "✓ $app_name: Remote-Icon OK"
                rm -f "$tmp"
                continue
            fi
            rm -f "$tmp"
            if [[ -n "$local_file" && -s "$local_file" ]] && grep -qi '<svg' "$local_file"; then
                echo "⚠ $app_name: Remote-Icon nicht verfügbar → lokales Fallback OK"
                continue
            fi
            echo "✗ $app_name: Remote-Icon und Fallback fehlen/ungültig"
            failed=1
        elif [[ -n "$local_file" && -s "$local_file" ]] && grep -qi '<svg' "$local_file"; then
            echo "✓ $app_name: lokales Icon OK"
        else
            echo "✗ $app_name: keine gültige Iconquelle"
            failed=1
        fi
    done
    return "$failed"
}

command_name="${1:-list}"

require_persisted_catalog() {
    [[ -s "$CATALOG_FILE" ]] || { echo "Katalog fehlt: $CATALOG_FILE" >&2; exit 20; }
    [[ -s "$APPLET_REGISTRY_FILE" ]] || { echo "Applet Registry fehlt: $APPLET_REGISTRY_FILE" >&2; exit 20; }
}

case "$command_name" in
  rebuild)
    acquire_mutation_lock "catalog-rebuild"
    rebuild_catalog
    echo "$CATALOG_FILE"
    ;;
  list)
    require_persisted_catalog
    acquire_read_lock "catalog-list"
    python3 - "$CATALOG_FILE" <<'PY_CAT'
import json,sys
j=json.load(open(sys.argv[1]))
for a in j['apps']:
    state='installed' if a['installed'] else 'available'
    print(f"{a['id']:<18} {a['category']:<12} {state:<10} {a['name']}")
PY_CAT
    ;;
  json)
    require_persisted_catalog
    acquire_read_lock "catalog-json"
    cat "$CATALOG_FILE"
    ;;
  check-icons) check_streaming_icons ;;
  validate) validate_all_apps ;;
  *) echo "Usage: $0 [list|json|rebuild|check-icons|validate]" >&2; exit 2 ;;
esac
