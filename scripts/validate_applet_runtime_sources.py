#!/usr/bin/env python3
from __future__ import annotations
import json
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
errors: list[str] = []

cli = (ROOT / 'bin/caelestia-webapps').read_text(encoding='utf-8')
watch = (ROOT / 'scripts/notification_watch.py').read_text(encoding='utf-8')

# statusIntegration is retained only as a catalog compatibility mirror. Runtime
# code is not allowed to consume it anymore.
for path in [ROOT / 'bin/caelestia-webapps', ROOT / 'scripts/notification_watch.py']:
    text = path.read_text(encoding='utf-8')
    if 'statusIntegration' in text:
        errors.append(f'{path.relative_to(ROOT)} still references statusIntegration')

required_cli = {
    'applet_runtime_entry': 'def applet_runtime_entry(',
    'registry_media_owner': 'def _media_candidate_for_player(player: str, registry_apps:',
    'registry_media_sessions': 'registry_apps = [a for a in load_applet_registry().get("apps", [])',
    'registry_status_feed': 'def integration_status_all() -> list[dict[str, Any]]:\n    registry = load_applet_registry()',
    'registry_single_status_feed': 'if len(args) == 2:\n            app = applet_runtime_entry(command, args[1])\n            success(command, data=integration_status_payload(app))',
    'registry_browser_video': 'app = applet_runtime_entry(command, args[1])\n        state, diagnostics = _browser_video_state_result(app)',
    'registry_media_control': 'app = applet_runtime_entry(command, args[1])\n        ok, detail = media_control_for_app(app, args[2])',
}
for name, token in required_cli.items():
    if token not in cli:
        errors.append(f'missing runtime registry invariant: {name}')

if '"applet-registry"' not in watch or 'app.get("adapter") == "notifications"' not in watch:
    errors.append('notification watcher is not registry-driven')

plugin_bar = (ROOT / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml').read_text(encoding='utf-8')
plugin_popout = (ROOT / 'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text(encoding='utf-8')
for label, text in [('GenericStatusBarEntry.qml', plugin_bar), ('GenericStatusPopout.qml', plugin_popout)]:
    if 'applet-entry' not in text:
        errors.append(f'{label} is not applet-registry driven')
    if 'cliCommand(["list"])' in text:
        errors.append(f'{label} still consumes catalog list metadata')
if 'if command == "applet-entry":' not in cli or 'applet_runtime_entry(command, app_id)' not in cli:
    errors.append('CLI applet-entry endpoint is not registry-backed')
if 'if (!root.runningStateAvailable)\n            return;' not in plugin_bar:
    errors.append('GenericStatusBarEntry.qml does not preserve confirmed running state on feed failure')
if 'caelestia-webapps: running-feed parse failed' in plugin_bar:
    tail = plugin_bar.split('caelestia-webapps: running-feed parse failed', 1)[1].split('}', 1)[0]
    if 'root.appRunning = false' in tail:
        errors.append('GenericStatusBarEntry.qml clears running state on parse failure')

# Catalog mirror may exist only in the generator/validator (plus tests/docs).
allowed = {
    Path('scripts/generate_catalog.py'),
    Path('scripts/validate_catalog.py'),
    Path('scripts/validate_applet_runtime_sources.py'),
}
for path in ROOT.rglob('*'):
    if not path.is_file():
        continue
    rel = path.relative_to(ROOT)
    if rel.parts[0] in {'tests', '.git'} or path.suffix == '.md':
        continue
    if rel in allowed:
        continue
    try:
        text = path.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        continue
    if 'statusIntegration' in text:
        errors.append(f'legacy statusIntegration escaped compatibility quarantine: {rel}')

report = {
    'ok': not errors,
    'data': {
        'runtimeMetadataSource': 'applet-registry.json',
        'legacyCatalogMirror': 'compatibility-only',
        'runtimeConsumers': ['status-feed', 'notification-watch', 'media-routing', 'browser-video-state', 'media-control', 'plugin-bar-entry', 'plugin-popout'],
        'violations': len(errors),
        'consistent': not errors,
    },
    'errors': errors,
}
print(json.dumps(report, ensure_ascii=False, indent=2))
raise SystemExit(0 if not errors else 1)
