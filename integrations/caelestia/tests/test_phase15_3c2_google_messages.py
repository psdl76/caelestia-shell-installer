#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parents[3]
plugin = root / 'integrations' / 'caelestia' / 'plugin'
manifest = json.loads((plugin/'manifest.json').read_text())

eps = {(e['type'], e.get('properties',{}).get('name') or e.get('properties',{}).get('entry')): e for e in manifest['entryPoints']}
assert ('bar-entry','webapp-google-messages') in eps
assert ('bar-popout','webapp-google-messages') in eps
assert eps[('bar-entry','webapp-google-messages')]['source'] == 'GoogleMessagesBarEntry.qml'
assert eps[('bar-popout','webapp-google-messages')]['source'] == 'GoogleMessagesPopout.qml'
assert 'appId: "google-messages"' in (plugin/'GoogleMessagesBarEntry.qml').read_text()
assert 'appId: "google-messages"' in (plugin/'GoogleMessagesPopout.qml').read_text()
entry=(plugin/'GenericStatusBarEntry.qml').read_text()
assert 'layer.enabled: status === Image.Ready' in entry
assert 'layer.effect: MultiEffect' in entry
assert 'colorizationColor: theme.barIcon' in entry
assert 'id: appIconMask' not in entry
print('Phase 15.3c.2 Google Messages generic instance: PASS')
