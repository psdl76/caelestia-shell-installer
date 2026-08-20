#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
GEN="$ROOT_DIR/scripts/generate_catalog.py"
SCHEMA="$ROOT_DIR/config/categories.json"

grep -Fq 'property string selectedCategory: "all"' "$WEB"
grep -Fq 'readonly property var visibleApps: apps.filter' "$WEB"
grep -Fq 'model: root.visibleApps' "$WEB"
grep -Fq 'id: allAnchor' "$WEB"
grep -Fq 'text: "Alle"' "$WEB"
grep -Fq 'model: root.categories' "$WEB"
grep -Fq 'root.categories = data.categories || []' "$WEB"
grep -Fq 'Flickable.HorizontalFlick' "$WEB"

grep -Fq '"categories": catalog_categories' "$GEN"
grep -Fq 'if category_counts.get(category_id, 0) > 0' "$GEN"
grep -Fq '"label": str(category.get("label", category_id))' "$GEN"

python3 -S - "$SCHEMA" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding="utf-8"))
cats=data["categories"]
assert cats["ai"]["label"] == "AI"
assert cats["messaging"]["label"] == "Messaging"
assert cats["streaming"]["label"] == "Streaming"
assert cats["ai"]["order"] < cats["messaging"]["order"] < cats["streaming"]["order"]
PY

echo "PASS: v7 categories are data-driven, populated-only and horizontally filterable"
