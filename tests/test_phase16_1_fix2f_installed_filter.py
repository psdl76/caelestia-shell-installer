from pathlib import Path
q = (Path(__file__).resolve().parents[1] / 'manager/shell.qml').read_text(encoding='utf-8')
assert '(selectedCategory === "installed" && app.installed === true)' in q
assert 'root.selectedCategory = "installed"' in q
assert 'Nur installierte WebApps anzeigen' in q
assert 'installedFilter.installedCount + " installiert"' in q
assert 'Keine WebApps installiert' in q
print('PASS: Phase16.1-fix2f installed-count filter')
