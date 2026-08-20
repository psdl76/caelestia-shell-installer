from pathlib import Path

root = Path(__file__).resolve().parents[1]
qml = (root / "manager/shell.qml").read_text()
preflight = (root / "scripts/manager_preflight.sh").read_text()

# Phase16.5-fix2 supersedes the temporary fix1 FileView guard. The historical
# regression remains satisfied because catalog access is now behind the CLI and
# the unsafe eager FileView path no longer exists at all.
assert 'id: catalogProcess' in qml
assert '[root.projectRoot + "/bin/caelestia-webapps", "list"]' in qml
assert 'FileView {\n        id: catalog' not in qml
assert 'catalog.reload()' not in qml
assert 'caelestia-webapps" refresh' in preflight
print("PASS: Phase16.5-fix1 startup race superseded by CLI catalog bridge")
