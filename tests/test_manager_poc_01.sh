#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT_DIR/manager/shell.qml"

[[ -f "$QML" ]]
[[ -x "$ROOT_DIR/manager.sh" ]]
grep -Fq 'FloatingWindow {' "$QML"
grep -Fq 'schemaVersion !== 2' "$QML"
grep -Fq 'model: [{ id: "all", label: "Alle" }].concat(root.categories)' "$QML"
grep -Fq 'function visibleApps()' "$QML"
grep -Fq 'Quickshell.execDetached([root.projectRoot + "/bin/caelestia-webapps", "launch", app.id])' "$QML"
grep -Fq 'watchChanges: true' "$QML"
! grep -Fq 'native-drawer-poc' "$QML"
! grep -Fq 'OriginalContent.qml' "$QML"
! grep -Fq 'modules/sidebar' "$QML"

echo 'PASS: manager-poc-01 is standalone, Catalog-v2 driven and free of Caelestia Sidebar patches'
