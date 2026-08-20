#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }
qml="$ROOT_DIR/manager/shell.qml"
pre="$ROOT_DIR/scripts/manager_preflight.sh"

grep -q 'id: startupWindow' "$qml" || fail "startup window missing"
grep -q 'visible: !root.startupReady' "$qml" || fail "startup visibility contract missing"
grep -q 'stdout: SplitParser' "$qml" || fail "streaming startup parser missing"
grep -q 'root.startupProgress' "$qml" || fail "progress state missing"
grep -q 'Style.Theme.toolbarSurface' "$qml" || fail "Caelestia-themed toolbar surface missing"
grep -q 'Style.Theme.primary' "$qml" || fail "scheme accent missing"
grep -q 'prepare_store_icons.sh' "$pre" || fail "icon startup stage missing"
grep -q 'caelestia_theme_bridge.py' "$pre" || fail "theme startup stage missing"
grep -q 'caelestia-webapps.*refresh' "$pre" || fail "catalog startup stage missing"
! grep -q 'prepare_store_icons.sh' "$ROOT_DIR/manager.sh" || fail "manager.sh must not block before Quickshell"
echo "PASS: Phase16.1-fix2a startup loader contract"
