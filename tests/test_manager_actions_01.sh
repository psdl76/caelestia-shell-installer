#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT_DIR/manager/shell.qml"
ACTION="$ROOT_DIR/manager/style/ActionButton.qml"
ICON="$ROOT_DIR/manager/style/IconButton.qml"

grep -Fq 'property bool actionBusy: false' "$QML"
grep -Fq 'id: actionProcess' "$QML"
grep -Fq 'function runAction(command, app)' "$QML"
grep -Fq 'actionProcess.command = [root.projectRoot + "/bin/caelestia-webapps", command, app.id]' "$QML"
grep -Fq 'root.runAction("setup", modelData)' "$QML"
grep -Fq 'root.runAction("repair", modelData)' "$QML"
grep -Fq 'root.runAction("install", modelData)' "$QML"
grep -Fq 'root.runAction(root.appRunning(app.id) ? "uninstall-close" : "uninstall", app)' "$QML"
grep -Fq 'root.runAction("launch", modelData)' "$QML"
grep -Fq 'catalog.reload()' "$QML"
grep -Fq 'root.refreshRuntimeSoon()' "$QML"
grep -Fq '"WebApp deinstallieren?"' "$QML"
grep -Fq 'root.pendingUninstallApp !== null' "$QML"

# Busy semantics moved into reusable controls in Phase 10.3.
grep -Fq 'interactive: !root.actionBusy' "$QML"
grep -Fq 'property bool interactive: true' "$ACTION"
grep -Fq 'enabled: root.interactive' "$ACTION"
grep -Fq 'property bool interactive: true' "$ICON"
grep -Fq 'enabled: root.interactive' "$ICON"

# Business logic stays out of QML.
! grep -Eq 'hyprctl|install\.sh|repair\.sh|uninstall\.sh' "$QML"
# Firefox may only appear in descriptive UI text, never executable commands.
! grep -Eq 'command:.*firefox|Process.*firefox' "$QML"

echo 'PASS: manager action bridge uses stable CLI with reusable busy-aware controls'
