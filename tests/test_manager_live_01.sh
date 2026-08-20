#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT_DIR/manager/shell.qml"
API="$ROOT_DIR/bin/caelestia-webapps"

grep -Fq 'watchChanges: true' "$QML"
grep -Fq 'onFileChanged: catalog.reload()' "$QML"
grep -Fq 'Process {' "$QML"
grep -Fq '"runtime"]' "$QML"
grep -Fq 'interval: 1500' "$QML"
grep -Fq 'property var runtimeByApp: ({})' "$QML"
grep -Fq 'function appRunning(appId)' "$QML"
grep -Fq 'color: Style.Theme.running' "$QML"
grep -Fq '? "Fokussieren" : "Öffnen"' "$QML"

grep -Fq 'def hyprland_window_state' "$API"
grep -Fq 'if command == "runtime":' "$API"
grep -Fq '"runtimeAvailable"' "$API"
grep -Fq '"windowCount"' "$API"

echo 'PASS: manager-live-01 watches Catalog v2 and keeps transient running state outside catalog.json'
