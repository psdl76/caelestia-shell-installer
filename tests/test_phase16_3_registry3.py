#!/usr/bin/env python3
from __future__ import annotations
import json, os, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
cli_text = (ROOT/'bin/caelestia-webapps').read_text(encoding='utf-8')
watch_text = (ROOT/'scripts/notification_watch.py').read_text(encoding='utf-8')
validator_text = (ROOT/'scripts/validate_applet_runtime_sources.py').read_text(encoding='utf-8')

# Runtime source quarantine.
assert 'statusIntegration' not in cli_text
assert 'statusIntegration' not in watch_text
assert 'def _media_candidate_for_player(player: str, registry_apps:' in cli_text
assert 'registry_apps = [a for a in load_applet_registry().get("apps", [])' in cli_text
assert 'def integration_status_all() -> list[dict[str, Any]]:\n    registry = load_applet_registry()' in cli_text
assert cli_text.count('app = applet_runtime_entry(command, args[1])') >= 2
assert "'build', 'dist', 'tests', 'tmp'" in validator_text

source_audit = subprocess.run([sys.executable, str(ROOT/'scripts/validate_applet_runtime_sources.py'), str(ROOT)], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
report = json.loads(source_audit.stdout)
assert report['ok'] is True
assert report['data']['runtimeMetadataSource'] == 'applet-registry.json'
assert report['data']['violations'] == 0

# Strong regression: status-feed must be able to run solely from a persisted
# applet registry, without generating/reading catalog.json at runtime.
with tempfile.TemporaryDirectory(prefix='cw-registry3-home-') as td:
    home = Path(td)
    data = home/'.local/share/caelestia-webapps'
    data.mkdir(parents=True)
    registry = {
        'schemaVersion': 1,
        'catalogSchemaVersion': 2,
        'apps': [
            {'id':'registry-only-a','defaultEnabled':False,'adapter':'notifications','support':'experimental','capabilities':['notifications'],'matchHosts':[],'windowClass':'registry-only-a','notificationMatches':['Registry A'],'browserBridge':{'kind':'none','port':0},'icon':{'provider':'test','id':'a'}},
            {'id':'registry-only-b','defaultEnabled':False,'adapter':'mail','support':'experimental','capabilities':['unread'],'matchHosts':[],'windowClass':'registry-only-b','notificationMatches':['Registry B'],'browserBridge':{'kind':'none','port':0},'icon':{'provider':'test','id':'b'}},
        ],
    }
    (data/'applet-registry.json').write_text(json.dumps(registry), encoding='utf-8')
    env=os.environ.copy(); env['HOME']=str(home); env['XDG_STATE_HOME']=str(home/'.local/state')
    proc=subprocess.run([sys.executable, str(ROOT/'bin/caelestia-webapps'), 'status-feed'], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    payload=json.loads(proc.stdout)
    ids=[x['appId'] for x in payload['data']['statuses']]
    assert ids == ['registry-only-a','registry-only-b'], ids
    assert payload['data']['statuses'][0]['kind'] == 'notification'
    assert payload['data']['statuses'][1]['kind'] == 'mail'

print('PASS: Phase16.3 registry3 single applet runtime metadata source')
