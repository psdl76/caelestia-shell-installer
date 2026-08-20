#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"

grep -Fq 'enabled: root.pendingUninstallApp !== null' "$QML"
grep -Fq 'onActivated: root.cancelUninstall()' "$QML"
grep -Fq 'enabled: root.wizardOpen && root.pendingUninstallApp === null' "$QML"
grep -Fq 'onActivated: root.closeWizard()' "$QML"

echo "PASS: Escape consistently closes the active modal layer"
