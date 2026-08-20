#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/data/apps" "$TMP/user"
python3 "$ROOT_DIR/scripts/generate_catalog.py" \
  "$ROOT_DIR/apps" "$TMP/user" "$TMP/data" "$TMP/catalog.json"
python3 "$ROOT_DIR/scripts/validate_catalog.py" "$TMP/catalog.json"
python3 - "$TMP/catalog.json" <<'PY'
import json,sys
j=json.load(open(sys.argv[1],encoding='utf-8'))
by={a['id']:a for a in j['apps']}
for app in j['apps']:
    a=app['applet']
    assert set(a)=={'available','defaultEnabled','adapter','support','capabilities','matchHosts'}
    assert app['statusIntegration']['capabilities'] == a['capabilities']

assert by['whatsapp']['applet'] == {
    'available': True,
    'defaultEnabled': False,
    'adapter': 'notifications',
    'support': 'supported',
    'capabilities': ['notifications','badge','preview'],
    'matchHosts': [],
}
assert by['google-messages']['applet']['adapter']=='notifications'
assert by['chatgpt']['applet']['adapter']=='none'
assert by['youtube']['applet']['adapter']=='media'
assert by['youtube']['applet']['support']=='supported'
assert by['youtube']['applet']['capabilities']==[
    'now_playing','playback_controls','live_preview','video_crop','pin'
]
assert by['youtube-music']['applet']['support']=='supported'
assert by['gmail']['applet']['adapter']=='mail'
assert by['google-calendar']['applet']['adapter']=='calendar'
assert by['proton-mail']['applet']['adapter']=='mail'
assert by['proton-calendar']['applet']['adapter']=='calendar'
assert by['chatgpt']['provider']=='openai'
assert by['whatsapp']['featured'] is True
assert all(not app['applet']['defaultEnabled'] for app in j['apps'])
print('Phase 16.1 applet capability data model: PASS')
PY
