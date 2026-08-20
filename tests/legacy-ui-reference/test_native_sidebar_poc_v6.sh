#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
BRIDGE="$ROOT_DIR/native-drawer-poc/native-action.sh"

grep -Fq 'property string expandedAppId: ""' "$WEB"
grep -Fq 'property var confirmApp: null' "$WEB"
grep -Fq 'Quickshell.execDetached([app.setupLauncher])' "$WEB"
grep -Fq 'root.runBackend(card.modelData, "repair")' "$WEB"
grep -Fq 'root.runBackend(app, "uninstall")' "$WEB"
grep -Fq 'text: "Setup"' "$WEB"
grep -Fq 'text: "Repair"' "$WEB"
grep -Fq 'text: "Entfernen"' "$WEB"

grep -Fq 'install|repair|uninstall' "$BRIDGE"
grep -Fq '"$PACKAGE_ROOT/repair.sh" --app "$APP_ID"' "$BRIDGE"
grep -Fq '"$PACKAGE_ROOT/uninstall.sh" "$APP_ID"' "$BRIDGE"
grep -Fq '"$PACKAGE_ROOT/catalog.sh" rebuild' "$BRIDGE"

echo "PASS: v6 wires Setup/Repair/Uninstall through native sidebar and tested backend"
