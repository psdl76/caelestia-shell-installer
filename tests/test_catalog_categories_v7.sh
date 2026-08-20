#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/defs" "$TMP/data/apps"
cp -a "$ROOT_DIR/apps/." "$TMP/defs/"
mkdir -p "$TMP/config"
cp "$ROOT_DIR/config/categories.json" "$TMP/config/categories.json"

# generator expects config next to definitions parent
mkdir -p "$TMP/project/apps" "$TMP/project/config"
cp -a "$ROOT_DIR/apps/." "$TMP/project/apps/"
cp "$ROOT_DIR/config/categories.json" "$TMP/project/config/categories.json"

python3 -S "$ROOT_DIR/scripts/generate_catalog.py" \
    "$TMP/project/apps" "$TMP/data" "$TMP/catalog.json"

python3 -S - "$TMP/catalog.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding="utf-8"))
assert data["schemaVersion"] == 2
assert isinstance(data["categories"], list)
assert len(data["categories"]) > 0
ids=[c["id"] for c in data["categories"]]
assert "ai" in ids
assert "messaging" in ids
assert "video" in ids
assert "music" in ids
assert "proton" in ids
assert all(c["count"] > 0 for c in data["categories"])
assert sum(c["count"] for c in data["categories"]) >= len(data["apps"])
assert all(a["category"] in a["categories"] for a in data["apps"])
teams=next(a for a in data["apps"] if a["id"] == "teams")
assert set(teams["categories"]) >= {"messaging", "microsoft"}
assert all("label" in c for c in data["categories"])
PY

echo "PASS: generated catalog contains only populated category metadata with correct counts"
