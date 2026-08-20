#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"

grep -Fq 'property int contentPage: 0' "$WEB"
grep -Fq 'id: actionTrack' "$WEB"
grep -Fq 'x: root.contentPage === 0 ? 0 : -actionViewport.width' "$WEB"
grep -Fq 'root.contentPage = 1' "$WEB"
grep -Fq 'root.contentPage = 0' "$WEB"
grep -Fq 'color: Colours.tPalette.m3surfaceContainerLow' "$WEB"
! grep -Fq 'opacity: 0.96' "$WEB"
! grep -Fq '// Native in-sidebar confirmation surface.' "$WEB"

echo "PASS: v6.1 replaces transparent uninstall overlay with opaque native sliding page"
