#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

assert_file "$ROOT_DIR/scripts/prepare_store_icons.sh"
bash -n "$ROOT_DIR/scripts/prepare_store_icons.sh" || fail "Store-Icon-Prep Syntax ungültig"
assert_contains "$ROOT_DIR/manager.sh" 'prepare_store_icons.sh'
assert_contains "$ROOT_DIR/manager.sh" 'catalog.sh" rebuild'
assert_contains "$ROOT_DIR/scripts/generate_catalog.py" '"iconStore": store_icon'
assert_contains "$ROOT_DIR/manager/shell.qml" 'app.iconStore'

# Every app must have either a valid bundled SVG or a remote SVG source that
# prepare_store_icons.sh can cache locally.
for conf in "$ROOT_DIR"/apps/*.conf; do
    (
        source "$conf"
        if [[ -n "${ICON_LOCAL_FILE:-}" && -s "${ICON_LOCAL_FILE:-}" ]] && grep -qi '<svg' "$ICON_LOCAL_FILE"; then
            exit 0
        fi
        [[ "${ICON_URL:-}" == https://* ]] || fail "$APP_ID hat weder lokales Store-Icon noch HTTPS-Iconquelle"
    )
done

pass "jede App besitzt eine lokale oder lokal cachebare Store-Iconquelle; Katalog wird vor Manager-Start aktualisiert"

assert_contains "$ROOT_DIR/apps/gemini.conf" 'dashboard-icons/svg/google-gemini.svg'
for app in paramount-plus wow; do
    assert_contains "$ROOT_DIR/apps/$app.conf" 'ICON_URL=""'
    assert_contains "$ROOT_DIR/apps/$app.conf" 'ICON_LOCAL_FILE='
done
if grep -q -- '--show-error' "$ROOT_DIR/scripts/prepare_store_icons.sh"; then
    fail "optionale Store-Icon-Downloads dürfen keine curl-Fehler in die Manager-Konsole schreiben"
fi

assert_contains "$ROOT_DIR/scripts/prepare_store_icons.sh" 'dashboard-icons/png/${ICON_NAME}.png'
assert_contains "$ROOT_DIR/scripts/prepare_store_icons.sh" 'is_png'
assert_contains "$ROOT_DIR/scripts/generate_catalog.py" 'store_png'
assert_contains "$ROOT_DIR/scripts/generate_catalog.py" 'store_svg'

assert_contains "$ROOT_DIR/scripts/prepare_store_icons.sh" '[[ "$APP_ID" == "gemini" ]] && prefer_png=true'
assert_contains "$ROOT_DIR/scripts/generate_catalog.py" 'if app_id == "gemini" and store_png.is_file()'
