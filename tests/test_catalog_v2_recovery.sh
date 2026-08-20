#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/project/apps" "$TMP/project/config" "$TMP/data/apps"
cp -a "$ROOT_DIR/apps/." "$TMP/project/apps/"
cp "$ROOT_DIR/config/categories.json" "$TMP/project/config/categories.json"
GEN=(python3 -S "$ROOT_DIR/scripts/generate_catalog.py" "$TMP/project/apps" "$TMP/data" "$TMP/catalog.json")
VAL=(python3 -S "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/catalog.json")

# Empty/invalid JSON must be replaced safely by a valid v2 catalog.
: > "$TMP/catalog.json"
"${GEN[@]}"
"${VAL[@]}"

printf '{broken json\n' > "$TMP/catalog.json"
"${GEN[@]}"
"${VAL[@]}"

# A stale v1 artifact must be migrated by regeneration even if its arrays look plausible.
cat > "$TMP/catalog.json" <<'JSON'
{"schemaVersion":1,"generatedAt":"old","categories":[],"apps":[]}
JSON
"${GEN[@]}"
"${VAL[@]}"
python3 -S - "$TMP/catalog.json" <<'PY'
import json,sys
assert json.load(open(sys.argv[1],encoding='utf-8'))['schemaVersion'] == 2
PY

# A valid unchanged v2 catalog must remain byte-for-byte stable (FileView friendly).
sha_before="$(sha256sum "$TMP/catalog.json" | awk '{print $1}')"
mtime_before="$(stat -c %Y "$TMP/catalog.json")"
sleep 1
"${GEN[@]}"
sha_after="$(sha256sum "$TMP/catalog.json" | awk '{print $1}')"
mtime_after="$(stat -c %Y "$TMP/catalog.json")"
[[ "$sha_before" == "$sha_after" ]]
[[ "$mtime_before" == "$mtime_after" ]]

echo "PASS: Catalog v2 recovers empty/corrupt/v1 state and stays untouched when unchanged"
