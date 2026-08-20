#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="$ROOT_DIR/apps/canva.conf"
grep -q '^ICON_PROVIDER="canva-official"$' "$CONF"
grep -q '^ICON_ID="android-192x192-2"$' "$CONF"
grep -q 'static.canva.com/domain-assets/canva/static/images/android-192x192-2.png' "$CONF"
echo "PASS: Phase16.1-fix2e Canva official icon mapping"
