#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/project/apps" "$TMP/project/config" "$TMP/data/apps/chatgpt"
cp -a "$ROOT_DIR/apps/." "$TMP/project/apps/"
cp "$ROOT_DIR/config/categories.json" "$TMP/project/config/categories.json"
printf 'APP_ID="chatgpt"\n' > "$TMP/data/apps/chatgpt/installed.conf"

python3 -S "$ROOT_DIR/scripts/generate_catalog.py" "$TMP/project/apps" "$TMP/data" "$TMP/catalog.json"
python3 -S "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/catalog.json"

python3 -S - "$TMP/catalog.json" <<'PY'
import json, sys
j=json.load(open(sys.argv[1],encoding='utf-8'))
assert j['schemaVersion'] == 2
assert isinstance(j['generatedAt'], str) and j['generatedAt']
assert all(set(('id','label','count','order')) <= set(c) for c in j['categories'])
assert [c['order'] for c in j['categories']] == sorted(c['order'] for c in j['categories'])
apps={a['id']:a for a in j['apps']}
chat=apps['chatgpt']
assert chat['installed'] is True
assert chat['source'] == 'builtin'
assert chat['capabilities'] == {
  'launch': True, 'setup': True, 'install': True, 'repair': True, 'uninstall': True, 'edit': False
}
assert chat['applet'] == {
  'available': False, 'defaultEnabled': False, 'adapter': 'none',
  'support': 'none', 'capabilities': [], 'matchHosts': []
}
# v1 fields remain present for compatibility with the accepted UI/data contract.
for key in ('name','genericName','comment','url','category','windowClass','iconName',
            'icon','iconLocal','iconUrl','iconStore','launcher','setupLauncher',
            'notificationMatch','notificationMatches','specialWorkspace',
            'appletVisible','appletShowBadge','appletNotificationPreview'):
    assert key in chat, key
PY

echo "PASS: Catalog v2 preserves v1 app data and adds stable source/capability/order contracts"
