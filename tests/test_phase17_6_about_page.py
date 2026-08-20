#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
HEADER = (ROOT / "manager/style/PageHeader.qml").read_text(encoding="utf-8")
DOC = ROOT / "docs/phases/phase-17/PHASE17_6_ABOUT_PAGE.md"

assert 'property string projectVersion: "–"' in SHELL
assert 'path: root.projectRoot + "/VERSION"' in SHELL
assert 'String(versionFile.text() ?? "").trim()' in SHELL

assert 'label: "Über"' in SHELL
assert 'description: "Projektinformationen und Credits"' in SHELL
assert 'selected: root.mainPage === "about"' in SHELL
assert 'onClicked: root.openAbout()' in SHELL

assert 'if (page === "about")\n            return aboutPage' in SHELL
assert 'if (page === "about")\n            return aboutPageTranslate' in SHELL
assert 'root.navigateMainPage("about", 1)' in SHELL

about = SHELL[SHELL.index("id: aboutPage"):SHELL.index("// Nexus StackPage equivalent")]
assert 'root.displayedMainPage === "about"' in about
assert 'title: "Über"' in about
assert "showBack: false" in about
assert 'text: "Caelestia WebApps"' in about
assert 'text: "v" + root.projectVersion' in about
assert 'value: "psdl76"' in about
assert 'value: "Caelestia Shell · Nexus"' in about
assert about.count("Style.SettingsInfoRow {") == 7

assert "property bool showBack: true" in HEADER
assert "visible: root.showBack" in HEADER
assert DOC.is_file()

print("PASS: Phase17.6 About page follows the Nexus top-level information layout")
