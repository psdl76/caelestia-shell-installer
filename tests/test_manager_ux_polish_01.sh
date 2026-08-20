#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"
ICON="$ROOT/manager/style/IconButton.qml"
API="$ROOT/bin/caelestia-webapps"

# Material destructive icon now lives as a reusable IconButton property.
grep -Fq 'icon: "\ue872"' "$QML"
grep -Fq 'font.family: "Material Symbols Rounded"' "$ICON"
grep -Fq 'text: "Aus dem Katalog entfernen"' "$QML"
grep -Fq '? "Schließen & deinstallieren"' "$QML"
grep -Fq 'root.runAction(root.appRunning(app.id) ? "uninstall-close" : "uninstall", app)' "$QML"

# Wizard keyboard flow remains intact; Escape is now also globally hardened.
grep -Fq 'KeyNavigation.tab: wizardId' "$QML"
grep -Fq 'KeyNavigation.tab: wizardUrl' "$QML"
grep -Fq 'KeyNavigation.tab: root.wizardIconMode === "url" ? wizardIcon : wizardSaveButton' "$QML"
grep -Fq 'KeyNavigation.tab: wizardSaveButton' "$QML"
grep -Fq 'onActivated: root.closeWizard()' "$QML"
grep -Fq 'id: wizardSaveButton' "$QML"

# Graceful close-before-uninstall remains engine-owned.
grep -Fq 'def graceful_close_windows' "$API"
grep -Fq 'hl.dsp.window.close' "$API"
grep -Fq 'window_close_timeout' "$API"
grep -Fq 'if command == "uninstall-close":' "$API"

! grep -Fq 'hyprctl' "$QML"

echo "PASS: UX polish uses shared controls while preserving graceful close and keyboard flow"
