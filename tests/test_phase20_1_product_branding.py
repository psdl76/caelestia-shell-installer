#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
ANIMATION = (ROOT / "manager/style/AnimatedBrandLogo.qml").read_text(encoding="utf-8")
DESKTOP = (ROOT / "packaging/caelestia-webapps-manager.desktop").read_text(encoding="utf-8")
INSTALL = (ROOT / "packaging/install-core.sh").read_text(encoding="utf-8")
UNINSTALL = (ROOT / "packaging/uninstall-core.sh").read_text(encoding="utf-8")

assert 'source: root.projectRoot + "/assets/branding/caelestia-webapps.svg"' in SHELL
assert "Style.AnimatedBrandLogo {" in SHELL
assert 'active: root.displayedMainPage === "about" && aboutPage.opacity > 0.99' in SHELL

assert "import qs." not in ANIMATION
assert "import Caelestia" not in ANIMATION
assert "ParallelAnimation" in ANIMATION
assert 'property: "rotation"' in ANIMATION
assert "to: 750" in ANIMATION
assert 'property: "scale"' in ANIMATION
assert "to: 1.08" in ANIMATION
assert 'property: "opacity"' in ANIMATION
assert "intro.restart()" in ANIMATION

assert "Icon=caelestia-webapps" in DESKTOP
assert 'ICON_DIR="$PREFIX/share/icons/hicolor/scalable/apps"' in INSTALL
assert '"$ICON_DIR/caelestia-webapps.svg"' in INSTALL
assert '"$PREFIX/share/icons/hicolor/scalable/apps/caelestia-webapps.svg"' in UNINSTALL

print("PASS: Phase 20.1 project branding and Nexus-inspired About animation")
