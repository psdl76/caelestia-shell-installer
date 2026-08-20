#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
STYLE = ROOT / "manager/style"
QMLDIR = (STYLE / "qmldir").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_5_WEBAPP_INFO_NAVIGATION.md"

catalog = SHELL[SHELL.index("model: root.visibleApps()"):SHELL.index("visible: root.catalogReady && root.visibleApps().length === 0")]
assert "Style.StateLayer {" in catalog
assert "onClicked: root.openActionMenu(modelData)" in catalog
assert 'text: "\\ue5cc"' in catalog
assert "topLeftRadius: index === 0" in catalog
assert "bottomLeftRadius: index === root.visibleApps().length - 1" in catalog
assert "Style.ActionButton {" not in catalog
assert 'label: "Installieren"' not in catalog
assert 'label: "Aktionen"' not in catalog

detail = SHELL[SHELL.index("id: actionPage"):SHELL.index("id: appletSettingsPage")]
assert 'title: "WebApp-Info"' in detail
assert "id: actionDetailsColumn" in detail
assert "root.iconSource(root.actionMenuApp)" in detail
assert "root.actionMenuApp.comment || root.actionMenuApp.genericName" in detail
assert "Style.SettingsToggle {" in detail
assert detail.count("Style.SettingsInfoRow {") == 4
for section in ('group: "WebApp"', 'group: "Applet"', 'group: "Verwaltung"', 'group: "Entfernen"'):
    assert section in SHELL

for action in ("launch", "install", "applet-toggle", "applet-settings", "setup", "repair", "edit", "remove"):
    assert f'id: "{action}"' in SHELL
assert 'root.runAction("launch", app)' in SHELL
assert 'root.runAction("install", app)' in SHELL
assert "root.toggleApplet(app)" in SHELL

# Catalog refresh keeps the open details page bound to current lifecycle state.
assert "const updatedApp = apps.find" in SHELL
assert "root.actionMenuApp = updatedApp" in SHELL
assert "root.closeActionMenu()" in SHELL

info = STYLE / "SettingsInfoRow.qml"
assert info.is_file()
assert "SettingsInfoRow 1.0 SettingsInfoRow.qml" in QMLDIR
info_text = info.read_text(encoding="utf-8")
assert "Theme.surfaceAlt" in info_text
assert "Tokens.radiusConnectedOuter" in info_text
assert "import qs." not in info_text
assert "import Caelestia" not in info_text

assert DOC.is_file()
doc = DOC.read_text(encoding="utf-8")
assert "AllApps.qml" in doc
assert "AppInfo.qml" in doc
assert "b1c9bbd" in doc

print("PASS: Phase17.5 catalog and WebApp info follow Nexus AllApps/AppInfo navigation")
