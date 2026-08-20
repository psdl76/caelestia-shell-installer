#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

for path in \
  "$ROOT_DIR/native-drawer-poc" \
  "$ROOT_DIR/caelestia-applet" \
  "$ROOT_DIR/applet.sh" \
  "$ROOT_DIR/native-drawer-poc.sh" \
  "$ROOT_DIR/lib/applet.sh" \
  "$ROOT_DIR/scripts/patch_bar.py" \
  "$ROOT_DIR/scripts/patch_notifications.py" \
  "$ROOT_DIR/scripts/patch_sidebar.py"; do
    [[ ! -e "$path" ]] || fail "UI/Caelestia-Patchartefakt im Engine-Core gefunden: $path"
done

for f in "$ROOT_DIR/install.sh" "$ROOT_DIR/repair.sh" "$ROOT_DIR/uninstall.sh" "$ROOT_DIR/lib"/*.sh "$ROOT_DIR/scripts"/*; do
    [[ -f "$f" ]] || continue
    if grep -Eq 'modules/(bar|sidebar)|StatusIcons\.qml|NotifData\.qml|Notifs\.qml|OriginalContent\.qml|WebAppsContent\.qml|patch_(bar|sidebar|notifications)\.py' "$f"; then
        fail "Engine-Datei enthält Caelestia-QML/Patch-Abhängigkeit: $f"
    fi
done

assert_contains "$ROOT_DIR/install.sh" 'The engine core has no UI/applet integration at all.'
assert_not_contains "$ROOT_DIR/install.sh" 'source "$LIB_DIR/applet.sh"'
assert_not_contains "$ROOT_DIR/uninstall.sh" 'applet.sh'
assert_not_contains "$ROOT_DIR/repair.sh" 'applet.sh repair'

pass "Engine-Core bleibt trotz separatem Manager von Caelestia/QML-UI-Implementierung entkoppelt"
