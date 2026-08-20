from pathlib import Path
q = (Path(__file__).resolve().parents[1] / 'manager/shell.qml').read_text(encoding='utf-8')
assert '(selectedCategory === "installed" && app.installed === true)' in q
assert '{ id: "installed", label: "Installiert" }' in q
assert 'onClicked: root.selectCategory(modelData.id, 1)' in q
assert 'return apps.filter(function(app) { return app.installed }).length' in q
assert 'Lokal eingerichtete WebApps' in q
assert 'Keine WebApps installiert' in q
print('PASS: Phase16.1-fix2f installed-count filter preserved in Phase17 navigation')
