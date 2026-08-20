#!/usr/bin/env python3
from __future__ import annotations
import json, subprocess, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'bin/caelestia-webapps'

def run(env, *args):
    return subprocess.run([str(CLI), *args], cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)

# Runtime status consumers must no longer use catalog.statusIntegration.
cli_text = CLI.read_text(encoding='utf-8')
watch_text = (ROOT / 'scripts/notification_watch.py').read_text(encoding='utf-8')
assert 'candidate.get("statusIntegration")' not in cli_text
assert 'app.get("statusIntegration")' not in cli_text
assert 'statusIntegration' not in watch_text
assert 'applet-registry' in watch_text

with tempfile.TemporaryDirectory() as home_dir:
    home = Path(home_dir)
    runtime = home / 'run'
    runtime.mkdir()
    env = {
        'HOME': str(home),
        'PATH': '/usr/bin:/bin',
        'XDG_CONFIG_HOME': str(home / 'config'),
        'XDG_DATA_HOME': str(home / 'data'),
        'XDG_STATE_HOME': str(home / 'state'),
        'XDG_CACHE_HOME': str(home / 'cache'),
        'XDG_RUNTIME_DIR': str(runtime),
        'CAELESTIA_WEBAPPS_DISABLE_NETWORK': '1',
    }

    # Runtime audit: the four supported applets are exactly the four dedicated Phase-15 implementations.
    p = run(env, 'validate-applet-runtime')
    assert p.returncode == 0, p.stderr
    payload = json.loads(p.stdout)
    data = payload['data']
    expected = ['google-messages', 'whatsapp', 'youtube', 'youtube-music']
    assert data['supported'] == 4
    assert data['implementedSupported'] == 4
    assert data['supportedAppIds'] == expected
    assert data['implementedAppIds'] == expected
    assert data['orphanImplementations'] == []
    assert data['consistent'] is True

    # Status feed still exposes all registry apps and preserves renderer protocol kinds.
    p = run(env, 'status-feed')
    assert p.returncode == 0, p.stderr
    statuses = json.loads(p.stdout)['data']['statuses']
    assert len(statuses) == 21
    by_id = {x['appId']: x for x in statuses}
    assert by_id['whatsapp']['kind'] == 'notification'
    assert by_id['google-messages']['kind'] == 'notification'
    assert by_id['youtube']['kind'] == 'media'
    assert by_id['youtube-music']['kind'] == 'media'

    # Negative implementation audit: remove one supported popout in a temporary manifest.
    registry = home / '.local/share/caelestia-webapps/applet-registry.json'
    manifest = json.loads((ROOT / 'integrations/caelestia/plugin/manifest.json').read_text(encoding='utf-8'))
    manifest['entryPoints'] = [
        x for x in manifest['entryPoints']
        if not (x.get('type') == 'bar-popout' and (x.get('properties') or {}).get('entry') == 'webapp-whatsapp')
    ]
    with tempfile.TemporaryDirectory() as td:
        mp = Path(td) / 'manifest.json'
        mp.write_text(json.dumps(manifest), encoding='utf-8')
        q = subprocess.run([
            'python3', str(ROOT / 'scripts/validate_applet_implementations.py'),
            str(registry), str(mp), str(ROOT / 'integrations/caelestia/plugin')
        ], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        assert q.returncode != 0
        report = json.loads(q.stdout)
        assert any('whatsapp: supported app missing dedicated bar-popout' in x for x in report['errors']), report

print('PASS: Phase16.3 registry2 runtime/implementation mapping')
