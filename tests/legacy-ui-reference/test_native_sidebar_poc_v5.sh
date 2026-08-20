#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
BRIDGE="$ROOT_DIR/native-drawer-poc/native-action.sh"
INSTALLER="$ROOT_DIR/native-drawer-poc.sh"

grep -Fq 'import qs.services' "$WEB"
grep -Fq 'Quickshell.execDetached([app.launcher])' "$WEB"
grep -Fq '[root.actionHelper, action, app.id]' "$WEB"
grep -Fq 'id: actionProcess' "$WEB"
grep -Fq 'Qt.callLater(root.reloadCatalog)' "$WEB"
grep -Fq '"$PACKAGE_ROOT/install.sh" "$APP_ID"' "$BRIDGE"
grep -Fq '[[ -f "$PACKAGE_ROOT/apps/$APP_ID.conf" ]]' "$BRIDGE"
grep -Fq 'caelestia-webapps-native-action' "$INSTALLER"
grep -Fq 'rm -f "$ACTION_HELPER"' "$INSTALLER"

echo "PASS: v5 wires native Open/Install to existing backend with catalog refresh"
