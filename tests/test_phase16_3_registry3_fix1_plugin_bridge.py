#!/usr/bin/env python3
from __future__ import annotations
import json, os, subprocess, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'bin/caelestia-webapps'
BAR = ROOT / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml'
POPOUT = ROOT / 'integrations/caelestia/plugin/GenericStatusPopout.qml'

for qml in (BAR, POPOUT):
    text = qml.read_text(encoding='utf-8')
    assert 'applet-entry' in text, qml
    assert 'cliCommand(["list"])' not in text, qml

with tempfile.TemporaryDirectory(prefix='cw-registry3-fix1-') as td:
    home = Path(td)
    reg = home / '.local/share/caelestia-webapps/applet-registry.json'
    reg.parent.mkdir(parents=True)
    reg.write_text(json.dumps({
        'schemaVersion': 1,
        'catalogSchemaVersion': 2,
        'apps': [{
            'id':'whatsapp','name':'WhatsApp','source':'builtin','adapter':'notifications',
            'support':'supported','defaultEnabled':False,'capabilities':['notifications','badge','preview'],
            'matchHosts':[],'windowClass':'whatsapp','notificationMatches':['WhatsApp'],
            'browserBridge':{'kind':'none','port':0},
            'icon':{'name':'whatsapp','provider':'dashboard-icons','id':'whatsapp'}
        }]
    }), encoding='utf-8')
    cache = home / '.cache/caelestia-webapps/store-icons-v6'
    cache.mkdir(parents=True)
    icon = cache / 'whatsapp.svg'
    icon.write_text('<svg xmlns="http://www.w3.org/2000/svg"></svg>', encoding='utf-8')
    env = os.environ.copy(); env['HOME'] = str(home); env.pop('XDG_CACHE_HOME', None)
    proc = subprocess.run([sys.executable, str(CLI), 'applet-entry', 'whatsapp'], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert proc.returncode == 0, proc.stderr
    payload = json.loads(proc.stdout)
    app = payload['data']['app']
    assert app['id'] == 'whatsapp'
    assert app['adapter'] == 'notifications'
    assert app['iconPath'] == str(icon)

print('PASS: Phase16.3 registry3-fix1 plugin registry bridge')
