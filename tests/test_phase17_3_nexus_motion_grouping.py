#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
STYLE = ROOT / "manager/style"
QMLDIR = (STYLE / "qmldir").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_3_NEXUS_MOTION_GROUPING.md"

# The route shown on screen changes only after the outgoing page faded out.
assert 'property string displayedMainPage: "catalog"' in SHELL
assert "function navigateMainPage(page, direction)" in SHELL
assert "if (mainPageSwitch.running)" in SHELL
assert "root.outgoingMainPageItem = root.pageItem(root.displayedMainPage)" in SHELL
assert "root.incomingMainPageItem = root.pageItem(page)" in SHELL
main_switch = SHELL[SHELL.index("id: mainPageSwitch"):]
fade_out = main_switch.index('property: "opacity"')
route_swap = main_switch.index("root.displayedMainPage = root.pendingMainPage")
fade_in = main_switch.index('from: 0', route_swap)
spatial_in = main_switch.index('property: "x"', route_swap)
assert fade_out < route_swap < fade_in < spatial_in
assert "root.mainPageDirection * Style.Tokens.space2xl * 3" in main_switch
assert "target: root.outgoingMainPageItem" in main_switch
assert "target: root.incomingMainPageItem" in main_switch
assert "target: root.incomingMainPageTranslate" in main_switch
assert "target: root.pageItem(root.displayedMainPage)" not in main_switch
assert SHELL.count("&& opacity > 0.01") == 4

# Category changes follow the same Nexus Pages sequence.
content_switch = SHELL[SHELL.index("id: contentSwitch"):SHELL.index("Style.WindowCloseDock")]
assert content_switch.index('to: 0') < content_switch.index("root.selectedCategory = root.pendingCategory")
assert content_switch.index("root.selectedCategory = root.pendingCategory") < content_switch.index('from: 0')
assert "root.categoryDirection * Style.Tokens.space2xl" in content_switch

# Old independent opacity/x Behaviors would cross-fade overlapping pages.
assert "Behavior on opacity { Style.EffectAnimation {} }" not in SHELL
assert "Behavior on x { Style.SpatialAnimation {} }" not in SHELL

# More Actions mirrors Nexus section headers and connected groups.
section = STYLE / "SectionHeader.qml"
assert section.is_file()
assert "SectionHeader 1.0 SectionHeader.qml" in QMLDIR
section_text = section.read_text(encoding="utf-8")
assert "Theme.textSecondary" in section_text
assert "Layout.leftMargin: Tokens.spaceLg" in section_text
for group in ('group: "Integration"', 'group: "Verwaltung"', 'group: "Entfernen"'):
    assert group in SHELL
assert "Style.SectionHeader {" in SHELL
assert "firstInSection" in SHELL
assert "lastInSection" in SHELL

# Hover and press feedback uses the same rounded Shape path as Nexus.
state_layer = (STYLE / "StateLayer.qml").read_text(encoding="utf-8")
assert "import QtQuick.Shapes" in state_layer
assert "ShapePath {" in state_layer
assert "fillGradient: RadialGradient" in state_layer
assert "function cornerRadius(name)" in state_layer

# Standalone code remains independent of private shell modules.
for path in (ROOT / "manager").rglob("*.qml"):
    text = path.read_text(encoding="utf-8")
    assert "import qs." not in text, path
    assert "import Caelestia" not in text, path

assert DOC.is_file()
doc = DOC.read_text(encoding="utf-8")
assert "b1c9bbd" in doc
assert "Pages.qml" in doc
assert "StackPage.qml" in doc

print("PASS: Phase17.3 Manager follows Nexus sequential motion and section grouping")
