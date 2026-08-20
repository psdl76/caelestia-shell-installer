#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
STYLE = ROOT / "manager/style"
QMLDIR = (STYLE / "qmldir").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_2_MANAGER_EMBEDDED_PAGES.md"

assert 'property string mainPage: "catalog"' in SHELL
assert 'root.navigateMainPage("actions", 1)' in SHELL
assert 'root.navigateMainPage("wizard", 1)' in SHELL
assert 'root.navigateMainPage("applet-settings", 1)' in SHELL

for page in ("wizard", "actions", "applet-settings"):
    assert f'enabled: root.displayedMainPage === "{page}" && opacity > 0.01' in SHELL

assert "id: mainPageSwitch" in SHELL
assert "SequentialAnimation {" in SHELL
assert SHELL.count("Style.PageHeader {") >= 3
assert SHELL.count("Style.SettingsSelect {") >= 2

for name in ("WindowCloseDock.qml", "SettingsAction.qml", "PageHeader.qml"):
    path = STYLE / name
    assert path.is_file(), name
    assert f"{name.removesuffix('.qml')} 1.0 {name}" in QMLDIR

close_dock = (STYLE / "WindowCloseDock.qml").read_text(encoding="utf-8")
settings_action = (STYLE / "SettingsAction.qml").read_text(encoding="utf-8")
page_header = (STYLE / "PageHeader.qml").read_text(encoding="utf-8")
assert 'icon: "\\ue5c4"' in page_header
assert "Style.WindowCloseDock {" in SHELL
assert "ShapePath {" in close_dock
assert 'fillColor: Theme.mainSurface' in close_dock
assert "Theme.surfaceAlt" in settings_action
assert "topLeftRadius: firstInGroup" in settings_action
assert "bottomLeftRadius: lastInGroup" in settings_action
assert "color: Theme.textSubtle" in settings_action
assert "function actionMenuEntries()" in SHELL
assert "Style.SettingsAction {" in SHELL
assert "ToolTip" not in SHELL
assert "tooltip:" not in SHELL
assert 'title: "WebApp-Info"' in SHELL
assert 'onClicked: root.openActionMenu(modelData)' in SHELL
assert "color: Style.Theme.surfaceAlt" in SHELL

# Destructive confirmation intentionally remains an overlay.
assert "visible: root.pendingUninstallApp !== null" in SHELL
assert "color: Style.Theme.scrimSoft" in SHELL

assert DOC.is_file()
doc = DOC.read_text(encoding="utf-8")
assert "ACCEPTED / FROZEN" in doc
assert "Destructive confirmation remains modal" in doc
assert "private Caelestia QML dependency" in doc

print("PASS: Phase17.2 Manager workflows are embedded animated main-surface pages")
