from pathlib import Path

qml = (Path(__file__).resolve().parents[1] / 'integrations/caelestia/plugin/GenericStatusBarEntry.qml').read_text()

assert 'if (runningProcess.running)' in qml
assert 'if (statusProcess.running)' in qml
assert 'const output = text.trim();' in qml
assert 'JSON.parse(output)' in qml
assert 'root.runningStateAvailable = false;' in qml
print('PASS: Phase16.4-fix1 non-overlapping polling + empty-output guard')
