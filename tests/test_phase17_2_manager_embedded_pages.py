#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_2_MANAGER_EMBEDDED_PAGES.md"

assert 'property string mainPage: "catalog"' in SHELL
assert 'root.mainPage = "actions"' in SHELL
assert 'root.mainPage = "wizard"' in SHELL
assert 'root.mainPage = "applet-settings"' in SHELL

for page in ("wizard", "actions", "applet-settings"):
    assert f'enabled: root.mainPage === "{page}"' in SHELL
    assert f'root.mainPage === "{page}" ? 0 : Style.Tokens.space2xl' in SHELL

assert SHELL.count("Behavior on opacity { Style.EffectAnimation {} }") >= 3
assert SHELL.count("Behavior on x { Style.SpatialAnimation {} }") >= 3
assert SHELL.count('tooltip: "Zurück"') >= 3
assert SHELL.count("Flow {") >= 2

# Destructive confirmation intentionally remains an overlay.
assert "visible: root.pendingUninstallApp !== null" in SHELL
assert "color: Style.Theme.scrimSoft" in SHELL

assert DOC.is_file()
doc = DOC.read_text(encoding="utf-8")
assert "IMPLEMENTATION CANDIDATE" in doc
assert "Destructive confirmation remains modal" in doc
assert "private Caelestia QML dependency" in doc

print("PASS: Phase17.2 Manager workflows are embedded animated main-surface pages")
