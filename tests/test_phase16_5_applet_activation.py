#!/usr/bin/env python3
from pathlib import Path
import ast
import json
import tempfile
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'bin/caelestia-webapps'
PLUGIN = ROOT / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml'
MANAGER = ROOT / 'manager/shell.qml'
source = CLI.read_text(encoding='utf-8')
module = ast.parse(source)

# Static contract: public commands are present and UI consumes only those commands.
assert 'applet-state|applet-set|' in source
plugin = PLUGIN.read_text(encoding='utf-8')
assert 'runtime.cliCommand(["applet-state", root.appId])' in plugin
assert 'visible: root.appletEnabled && root.appRunning' in plugin
assert 'if (activationProcess.running)' in plugin
manager = MANAGER.read_text(encoding='utf-8')
assert '"applet-set"' in manager
assert 'modelData.applet?.support === "supported"' in manager
assert 'root.appletEnabled(modelData.id) ? "Applet an" : "Applet aus"' in manager

# Execute the state helpers in isolation to verify persistence/default semantics.
names = {
    '_applet_activation_path', '_read_applet_activation_overrides',
    'applet_activation_available', 'applet_enabled', 'set_applet_enabled'
}
nodes = [n for n in module.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert {n.name for n in nodes} == names
with tempfile.TemporaryDirectory(prefix='cw16_5-') as td:
    state_root = Path(td)
    ns: dict[str, Any] = {
        'Path': Path,
        'json': json,
        'Any': Any,
        '_state_root': lambda: state_root,
        'applet_runtime_entry': lambda command, app_id: {'id': app_id, 'defaultEnabled': False, 'support': 'supported'},
    }
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(CLI), 'exec'), ns)
    available = ns['applet_activation_available']
    enabled = ns['applet_enabled']
    set_enabled = ns['set_applet_enabled']
    assert available({'support': 'supported'}) is True
    assert available({'support': 'experimental'}) is False
    entry = {'id': 'youtube', 'defaultEnabled': False, 'support': 'supported'}
    assert enabled('youtube', entry) is False
    set_enabled('youtube', True)
    assert enabled('youtube', entry) is True
    payload = json.loads((state_root / 'applets.json').read_text(encoding='utf-8'))
    assert payload == {'schemaVersion': 1, 'enabled': {'youtube': True}}
    set_enabled('youtube', False)
    assert enabled('youtube', entry) is False

print('PASS: Phase16.5 optional applet activation state + CLI/UI bridge')
