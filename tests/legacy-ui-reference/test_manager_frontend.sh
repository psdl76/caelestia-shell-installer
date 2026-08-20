#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

qml="$ROOT_DIR/manager/shell.qml"
launcher="$ROOT_DIR/manager.sh"

assert_file "$qml"
assert_file "$launcher"
assert_contains "$qml" 'catalog.json'
assert_contains "$qml" '/install.sh'
assert_contains "$qml" '/uninstall.sh'
assert_contains "$qml" '/repair.sh'
assert_contains "$qml" 'setupLauncher'
assert_contains "$qml" 'app.launcher'

if grep -Eq 'rules\.lua|keybinds\.lua|userChrome|profile/chrome|StatusIcons\.qml' "$qml"; then
    fail "Manager enthält direkte Konfigurations-/Patchlogik"
fi

assert_contains "$qml" 'messaging'
assert_contains "$qml" 'streaming'
assert_contains "$qml" '"ai"'
assert_contains "$qml" 'Installieren'
assert_contains "$qml" 'Deinstallieren'

assert_contains "$qml" 'iconLocal'
assert_contains "$qml" 'iconStore'
assert_contains "$qml" 'onVisibleChanged'
assert_contains "$qml" 'Qt.quit()'
assert_contains "$qml" 'implicitWidth: 980'
assert_contains "$qml" 'implicitHeight: 690'

bash -n "$launcher" || fail "manager.sh Syntax ungültig"
pass "WebApps Manager ist eine reine GUI-Schicht über dem getesteten Backend"
