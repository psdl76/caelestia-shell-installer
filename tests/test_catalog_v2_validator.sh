#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/project/apps" "$TMP/project/config" "$TMP/data/apps"
cp -a "$ROOT_DIR/apps/." "$TMP/project/apps/"
cp "$ROOT_DIR/config/categories.json" "$TMP/project/config/categories.json"
python3 -S "$ROOT_DIR/scripts/generate_catalog.py" "$TMP/project/apps" "$TMP/data" "$TMP/catalog.json"

python3 -S "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/catalog.json"

python3 -S - "$TMP/catalog.json" "$TMP/bad.json" <<'PY'
import json,sys
j=json.load(open(sys.argv[1],encoding='utf-8'))
j['apps'][1]['id']=j['apps'][0]['id']
json.dump(j,open(sys.argv[2],'w',encoding='utf-8'))
PY
if python3 -S "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/bad.json" >/dev/null 2>&1; then
  echo "validator accepted duplicate app id" >&2
  exit 1
fi

python3 -S - "$TMP/catalog.json" "$TMP/bad.json" <<'PY'
import json,sys
j=json.load(open(sys.argv[1],encoding='utf-8'))
j['categories'][0]['count'] += 1
json.dump(j,open(sys.argv[2],'w',encoding='utf-8'))
PY
if python3 -S "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/bad.json" >/dev/null 2>&1; then
  echo "validator accepted category count mismatch" >&2
  exit 1
fi

echo "PASS: Catalog v2 validator rejects duplicate IDs and inconsistent category counts"
