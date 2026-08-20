import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
plugin = root / 'integrations/caelestia/plugin'
manifest = json.loads((plugin/'manifest.json').read_text())

eps = manifest['entryPoints']
assert any(e['type']=='bar-entry' and e['source']=='WhatsAppBarEntry.qml' and e['properties'].get('name')=='webapp-whatsapp' for e in eps)
assert any(e['type']=='bar-popout' and e['source']=='WhatsAppPopout.qml' and e['properties'].get('entry')=='webapp-whatsapp' for e in eps)

for fn in ['CliRuntime.qml','GenericStatusBarEntry.qml','GenericStatusPopout.qml','WhatsAppBarEntry.qml','WhatsAppPopout.qml']:
    assert (plugin/fn).exists(), fn

assert 'appId: "whatsapp"' in (plugin/'WhatsAppBarEntry.qml').read_text()
assert 'appId: "whatsapp"' in (plugin/'WhatsAppPopout.qml').read_text()
assert 'current + ":" + localBin' in (plugin/'CliRuntime.qml').read_text()
assert 'localBin + ":" + current' not in (plugin/'CliRuntime.qml').read_text()
print('Phase 15.3c generic per-app entry contract: PASS')
