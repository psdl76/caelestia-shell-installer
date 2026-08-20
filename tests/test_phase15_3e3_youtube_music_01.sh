#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python - "$ROOT" <<'PY'
import json, pathlib, sys
root=pathlib.Path(sys.argv[1])
conf=(root/'apps/youtube-music.conf').read_text()
for needle in [
    'APP_ID="youtube-music"',
    'APP_URL="https://music.youtube.com/"',
    'WINDOW_CLASS="youtube-music"',
    'STATUS_INTEGRATION_TYPE="media"',
    'artwork',
]:
    assert needle in conf, needle
manifest=json.loads((root/'integrations/caelestia/plugin/manifest.json').read_text())
by=[]
for e in manifest['entryPoints']:
    props=e.get('properties',{})
    by.append((e['type'], props.get('name') or props.get('entry'), e['source']))
assert ('bar-entry','webapp-youtube-music','YouTubeMusicBarEntry.qml') in by
assert ('bar-popout','webapp-youtube-music','YouTubeMusicPopout.qml') in by
assert 'appId: "youtube-music"' in (root/'integrations/caelestia/plugin/YouTubeMusicBarEntry.qml').read_text()
assert 'appId: "youtube-music"' in (root/'integrations/caelestia/plugin/YouTubeMusicPopout.qml').read_text()
# Core must stay generic: no YouTube Music branch in renderer.
pop=(root/'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text().lower()
assert 'youtube-music' not in pop
print('Phase 15.3e.3 YouTube Music generic media instance: PASS')
PY
