#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/data"
python3 "$ROOT_DIR/scripts/generate_catalog.py" "$ROOT_DIR/apps" "$TMP/no-user" "$TMP/data" "$TMP/catalog.json"
python3 "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/catalog.json"
python3 - "$TMP/catalog.json" "$ROOT_DIR/manager/shell.qml" <<'PY'
import json, pathlib, sys
catalog=json.load(open(sys.argv[1], encoding='utf-8'))
qml=pathlib.Path(sys.argv[2]).read_text(encoding='utf-8')
assert len(catalog['apps']) == 79
assert any(a['featured'] for a in catalog['apps'])
assert 'property string selectedCategory: "featured"' in qml
assert '{ id: "featured", label: root.categoryLabel("featured") }' in qml
assert '"featured": Style.I18n.choose("Empfohlen", "Featured")' in qml
assert 'id: navigationScroll' in qml
assert 'Style.NavigationItem {' in qml
assert 'contentHeight: navigationColumn.implicitHeight' in qml
assert 'app.categories || [app.category]' in qml
assert 'if (app.source === "user" && (app.iconUrl ?? "").length > 0)' in qml
# Remote icon URLs are user-app-only; built-ins use local store/local fallback.
assert qml.index('if (app.source === "user" && (app.iconUrl ?? "").length > 0)') < qml.index('if ((app.iconLocal ?? "").length > 0)')
teams=next(a for a in catalog['apps'] if a['id']=='teams')
assert teams['categories'] == ['messaging','microsoft']
assert 'Firefox App-Modus' not in teams['comment']
for app in catalog['apps']:
    assert app['comment'].strip()
    assert 'Firefox App-Modus' not in app['comment']
    assert app['category'] in app['categories']
PY

echo "PASS: Phase16.1-fix1 catalog data/featured contract preserved in Phase17 navigation"
