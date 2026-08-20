#!/usr/bin/env python3
from pathlib import Path
import json, os, subprocess, tempfile

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'bin/caelestia-webapps'
QML = ROOT / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml'

cli = CLI.read_text(encoding='utf-8')
qml = QML.read_text(encoding='utf-8')

# Single-app status-feed must use the authoritative registry projection.
needle = '''if len(args) == 2:\n            app = applet_runtime_entry(command, args[1])\n            success(command, data=integration_status_payload(app))'''
assert needle in cli, 'single-app status-feed is not registry-backed'
assert 'app = app_from_catalog(command, args[1])\n            success(command, data=integration_status_payload(app))' not in cli

# Running visibility must survive transient feed/parse failures.
assert 'if (!root.runningStateAvailable)\n            return;' in qml
parse_section = qml.split('caelestia-webapps: running-feed parse failed', 1)[1].split('}', 1)[0]
assert 'root.appRunning = false' not in parse_section

# BiDi diagnostics must report the complete context tree, not label matching count as total.
for token in ['topLevelContexts', 'totalContexts', 'matchingContexts', 'contextSummaries', 'matchHost']:
    assert f'diagnostics["{token}"]' in cli, f'missing BiDi diagnostic {token}'

# Live isolated registry test: one-app status must preserve media adapter/capabilities.
with tempfile.TemporaryDirectory() as td:
    home = Path(td)
    share = home / '.local/share/caelestia-webapps'
    share.mkdir(parents=True)
    registry = {
        'schemaVersion': 1,
        'apps': [{
            'id': 'youtube', 'name': 'YouTube', 'adapter': 'media',
            'support': 'supported', 'defaultEnabled': False,
            'capabilities': ['now_playing','playback_controls','live_preview','video_crop','pin'],
            'matchHosts': ['youtube.com'], 'notificationMatches': [],
            'browserBridge': {'kind':'webdriver-bidi','port':9341},
            'icon': {'name':'youtube','provider':'dashboard-icons','id':'youtube'}
        }]
    }
    (share/'applet-registry.json').write_text(json.dumps(registry), encoding='utf-8')
    env = os.environ.copy(); env['HOME'] = str(home); env['XDG_STATE_HOME'] = str(home/'.local/state')
    p = subprocess.run([str(CLI), 'status-feed', 'youtube'], env=env, text=True, capture_output=True)
    assert p.returncode == 0, p.stderr + p.stdout
    payload = json.loads(p.stdout)
    assert payload['data']['appId'] == 'youtube'
    assert payload['data']['kind'] == 'media', payload
    # Runtime availability may be false in the isolated test, but registry capabilities must remain.
    assert 'live_preview' in payload['data']['capabilities'], payload

print('PASS: Phase16.3 registry3-fix2 stable running state + registry single status + BiDi diagnostics')
