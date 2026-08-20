from pathlib import Path
p = Path(__file__).resolve().parents[1] / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml'
s = p.read_text()
assert 'Loader {' in s
assert 'active: root.iconSource.length > 0' in s
assert 'asynchronous: false' in s
assert 'layer.enabled: status === Image.Ready' in s
assert 'icon load failed' in s
assert 'Timer {' in s  # status polling remains intentional; no icon-delay timer added
assert 'interval: 2000' in s
print('Phase 15.3d.1 fix1 deterministic icon contract: PASS')
