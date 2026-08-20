#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
STYLE = ROOT / "manager/style"
QMLDIR = (STYLE / "qmldir").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_1_MANAGER_NEXUS_LAYOUT.md"

for name in (
    "StateLayer.qml",
    "NavigationItem.qml",
    "SpatialAnimation.qml",
    "EffectAnimation.qml",
):
    path = STYLE / name
    assert path.is_file(), name
    text = path.read_text(encoding="utf-8")
    assert "import qs." not in text
    assert "import Caelestia" not in text
    assert f"{name.removesuffix('.qml')} 1.0 {name}" in QMLDIR

for name in ("ActionButton.qml", "IconButton.qml"):
    text = (STYLE / name).read_text(encoding="utf-8")
    assert "StateLayer {" in text, name
    assert "state.pressed" in text, name

assert "implicitWidth: 1180" in SHELL
assert "minimumSize.width: 920" in SHELL
assert "Style.Tokens.navigationWidth" in SHELL
assert "Style.NavigationItem {" in SHELL
assert "id: navigationScroll" in SHELL
assert "id: contentPane" in SHELL
assert "id: contentSwitch" in SHELL
assert "Style.SpatialAnimation" in SHELL
assert "Style.EffectAnimation" in SHELL
assert 'tooltip: "Manager schließen"' in SHELL
assert "function selectCategory(id, direction)" in SHELL
assert "categoryFlick" not in SHELL
assert SHELL.index("id: managerSearch") < SHELL.index("id: contentPane")

assert DOC.is_file()
doc = DOC.read_text(encoding="utf-8")
assert "IMPLEMENTATION CANDIDATE" in doc
assert "does not import `qs.*`" in doc

print("PASS: Phase17.1 Manager uses project-owned Caelestia Nexus navigation and motion primitives")
