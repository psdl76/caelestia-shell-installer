#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
qml = (root / 'manager' / 'shell.qml').read_text(encoding='utf-8')

assert 'property bool actionMenuOpen: false' in qml
assert 'property var actionMenuApp: null' in qml
assert 'function openActionMenu(app)' in qml
assert 'function closeActionMenu()' in qml
assert 'title: "WebApp-Info"' in qml
assert 'onClicked: root.openActionMenu(modelData)' in qml
assert 'text: "\\ue5cc"' in qml
assert "ToolTip" not in qml
assert "tooltip:" not in qml

# The dense installed-app toolbar must no longer expose the four secondary icon actions.
installed_row = qml[qml.index('model: root.visibleApps()'):qml.index('visible: root.catalogReady && root.visibleApps().length === 0')]
assert 'tooltip: "Applet-Einstellungen"' not in installed_row
assert 'tooltip: "Firefox-Profil einrichten / Berechtigungen"' not in installed_row
assert 'tooltip: "WebApp reparieren"' not in installed_row
assert 'tooltip: "WebApp deinstallieren"' not in installed_row
assert 'Style.ActionButton {' not in installed_row
assert 'onClicked: root.openActionMenu(modelData)' in installed_row

for label in [
    'Applet-Einstellungen',
    'Firefox-Profil & Berechtigungen',
    'WebApp reparieren',
    'Eigene WebApp bearbeiten',
    'WebApp deinstallieren',
]:
    assert label in qml, label

for explanation in [
    'Funktionen wie Badge, Vorschau oder Wiedergabesteuerung konfigurieren.',
    'WebApp-Profil erneut einrichten und benötigte Firefox-Berechtigungen vorbereiten.',
    'Installation prüfen und verwaltete Dateien sowie Metadaten erneut herstellen.',
    'Name, URL, Kategorie und Icon der eigenen WebApp ändern.',
]:
    assert explanation in qml, explanation

# Secondary actions still delegate to the existing stable manager functions/CLI bridge.
assert 'root.runAction("setup", app)' in qml
assert 'root.runAction("repair", app)' in qml
assert 'root.openAppletSettings(app)' in qml
assert 'root.openEditWizard(app)' in qml
assert 'root.requestUninstall(app)' in qml

print('PASS: Phase16.6-fix1 compact more-actions dialog')
