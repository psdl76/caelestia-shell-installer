#!/usr/bin/env python3
from pathlib import Path
import ast
import json
import tempfile
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'bin/caelestia-webapps'
BAR = ROOT / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml'
POPOUT = ROOT / 'integrations/caelestia/plugin/GenericStatusPopout.qml'
MANAGER = ROOT / 'manager/shell.qml'
source = CLI.read_text(encoding='utf-8')
module = ast.parse(source)

assert 'applet-settings|applet-setting-set|' in source
assert '"applet-settings"' in source
assert '"applet-setting-set"' in source

bar = BAR.read_text(encoding='utf-8')
assert 'runtime.cliCommand(["applet-settings", root.appId])' in bar
assert 'root.capabilityEnabled("badge")' in bar
assert 'root.capabilityEnabled("notifications")' in bar

popout = POPOUT.read_text(encoding='utf-8')
assert 'runtime.cliCommand(["applet-settings", root.appId])' in popout
for capability in ['notifications', 'preview', 'now_playing', 'playback_controls', 'live_preview', 'video_crop', 'pin', 'artwork']:
    assert f'capabilityEnabled("{capability}")' in popout

manager = MANAGER.read_text(encoding='utf-8')
assert 'Applet-Einstellungen' in manager
assert 'applet-setting-set' in manager
assert 'applet-settings' in manager
assert 'app.applet?.support === "supported"' in manager

names = {
    '_applet_settings_path', '_read_applet_settings_overrides',
    'applet_capability_enabled', 'set_applet_capability'
}
nodes = [n for n in module.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert {n.name for n in nodes} == names

with tempfile.TemporaryDirectory(prefix='cw16_6-') as td:
    state_root = Path(td)
    entry = {
        'id': 'youtube',
        'support': 'supported',
        'capabilities': ['now_playing', 'playback_controls', 'live_preview', 'video_crop', 'pin'],
    }
    def fail_error(command, code, message, exit_code):
        raise RuntimeError((command, code, message, exit_code))
    ns: dict[str, Any] = {
        'Path': Path,
        'json': json,
        'Any': Any,
        '_state_root': lambda: state_root,
        'applet_runtime_entry': lambda command, app_id: entry,
        'error': fail_error,
        'EXIT_ACTION_FAILED': 5,
    }
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(CLI), 'exec'), ns)
    enabled = ns['applet_capability_enabled']
    set_cap = ns['set_applet_capability']

    # Registry capabilities default to on; unknown capabilities are off.
    assert enabled('youtube', 'live_preview', entry) is True
    assert enabled('youtube', 'artwork', entry) is False

    set_cap('youtube', 'live_preview', False, entry)
    assert enabled('youtube', 'live_preview', entry) is False
    payload = json.loads((state_root / 'applet-settings.json').read_text(encoding='utf-8'))
    assert payload == {'schemaVersion': 1, 'apps': {'youtube': {'live_preview': False}}}

    set_cap('youtube', 'live_preview', True, entry)
    assert enabled('youtube', 'live_preview', entry) is True

    try:
        set_cap('youtube', 'artwork', False, entry)
    except RuntimeError as exc:
        assert exc.args[0][1] == 'unknown_capability'
    else:
        raise AssertionError('unknown capability accepted')

print('PASS: Phase16.6 persistent capability settings + Manager/plugin runtime bridge')
