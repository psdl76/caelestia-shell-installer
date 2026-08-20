#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WRAP="$ROOT_DIR/native-drawer-poc/Content.qml"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
grep -Fq 'id: pageTrack' "$WRAP"
grep -Fq 'x: root.currentPage === 0 ? 0 : -viewport.width' "$WRAP"
grep -Fq 'id: activePill' "$WRAP"
grep -Fq 'Behavior on x' "$WRAP"
grep -Fq 'color: Colours.palette.m3onSurface' "$WEB"
grep -Fq 'color: Colours.palette.m3onSurfaceVariant' "$WEB"
echo "PASS: native sidebar v3 uses explicit theme text colours and one animated page track"
