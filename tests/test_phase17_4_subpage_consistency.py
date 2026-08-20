#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
STYLE = ROOT / "manager/style"
QMLDIR = (STYLE / "qmldir").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_4_SUBPAGE_CONSISTENCY.md"

components = {
    "PageHeader.qml": "PageHeader",
    "SettingsToggle.qml": "SettingsToggle",
    "SettingsTextField.qml": "SettingsTextField",
    "SettingsSelect.qml": "SettingsSelect",
}
for filename, typename in components.items():
    path = STYLE / filename
    assert path.is_file(), filename
    text = path.read_text(encoding="utf-8")
    assert f"{typename} 1.0 {filename}" in QMLDIR
    assert "import qs." not in text
    assert "import Caelestia" not in text

# All embedded subpages share one header component.
# Phase 17.6 adds the top-level About header to the three workflow headers.
assert SHELL.count("Style.PageHeader {") == 4
assert 'title: "WebApp-Info"' in SHELL
assert "id: actionDetailsColumn" in SHELL
assert 'subtitle: "Verfügbare Funktionen des Caelestia-Applets"' in SHELL

wizard = SHELL[SHELL.index("id: wizardPage"):SHELL.index("id: actionPage")]
assert wizard.count("Style.SectionHeader {") >= 3
assert wizard.count("Style.SettingsTextField {") == 4
assert wizard.count("Style.SettingsSelect {") == 2
assert "Flow {" not in wizard
assert 'text: "WebApp"' in wizard
assert 'text: "Darstellung"' in wizard
assert 'text: "Vorschau"' in wizard

applet = SHELL[SHELL.index("id: appletSettingsPage"):SHELL.index("id: mainPageSwitch")]
assert 'text: "Funktionen"' in applet
assert "delegate: Style.SettingsToggle {" in applet
assert "firstInGroup: index === 0" in applet
assert "lastInGroup: index === root.appletSettingsItems.length - 1" in applet

# The modal remains modal, but does not invent a second switch design.
confirmation = SHELL[SHELL.index("visible: root.pendingUninstallApp !== null"):]
assert "Style.SettingsToggle {" in confirmation
assert 'title: "Aus dem Katalog entfernen"' in confirmation

toggle = (STYLE / "SettingsToggle.qml").read_text(encoding="utf-8")
field = (STYLE / "SettingsTextField.qml").read_text(encoding="utf-8")
select = (STYLE / "SettingsSelect.qml").read_text(encoding="utf-8")
for text in (toggle, field, select):
    assert "Theme.surfaceAlt" in text
    assert "Tokens.radiusConnectedOuter" in text
    assert "Tokens.radiusConnectedInner" in text
assert "StateLayer {" in toggle
assert "Popup {" in select
assert "closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside" in select
assert "ToolTip" not in SHELL

assert DOC.is_file()
doc = DOC.read_text(encoding="utf-8")
for reference in ("TextFieldRow", "ToggleRow", "ConnectedRect", "b1c9bbd"):
    assert reference in doc

print("PASS: Phase17.4 all Manager subpages use one Nexus settings grammar")
