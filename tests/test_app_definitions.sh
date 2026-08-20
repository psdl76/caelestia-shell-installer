#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

required=(APP_ID APP_NAME APP_URL APP_CATALOG_CATEGORY MOZ_APP_REMOTINGNAME WINDOW_CLASS ICON_NAME USE_OPAQUE_TAG)
count=0
for f in "$ROOT_DIR"/apps/*.conf; do
    (
        set -u
        source "$f"
        for key in "${required[@]}"; do
            [[ -n "${!key:-}" ]] || fail "$(basename "$f"): $key fehlt/ist leer"
        done
        [[ "$APP_ID" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "$(basename "$f"): ungültige APP_ID"
        [[ "$WINDOW_CLASS" =~ ^[A-Za-z0-9._-]+$ ]] || fail "$(basename "$f"): ungültige WINDOW_CLASS"
        [[ "$APP_URL" =~ ^https:// ]] || fail "$(basename "$f"): APP_URL muss https:// verwenden"
        case "$APP_CATALOG_CATEGORY" in
            ai|messaging|google|microsoft|proton|productivity|social|video|music|development|design|cloud|shopping|travel) ;;
            *) fail "$(basename "$f"): unbekannte Kategorie $APP_CATALOG_CATEGORY" ;;
        esac
        for key in USE_OPAQUE_TAG APPLET_VISIBLE APPLET_SHOW_BADGE APPLET_NOTIFICATION_PREVIEW; do
            b="${!key:-}"
            [[ -z "$b" || "$b" == true || "$b" == false ]] || fail "$(basename "$f"): $key ist kein boolescher Wert"
        done
    )
    ((count+=1))
done
((count > 0)) || fail "Keine App-Definitionen gefunden"
pass "$count App-Definitionen validiert"
