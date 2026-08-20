#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WRAP="$ROOT_DIR/native-drawer-poc/Content.qml"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
SCRIPT="$ROOT_DIR/native-drawer-poc.sh"

grep -Fq 'import qs.services' "$WEB"
grep -Fq 'color: Colours.palette.m3onSurface' "$WEB"
grep -Fq 'color: Colours.palette.m3onSurfaceVariant' "$WEB"
grep -Fq 'id: pageTrack' "$WRAP"
grep -Fq 'id: activePill' "$WRAP"
grep -Fq 'cp -a "$BACKUP" "$sidebar_dir/OriginalContent.qml"' "$SCRIPT"
grep -Fq 'rm -f "$sidebar_dir/OriginalContent.qml" "$sidebar_dir/WebAppsContent.qml"' "$SCRIPT"

echo "PASS: v4 preserves native sidebar, sliding UI and verified Caelestia theme imports"
