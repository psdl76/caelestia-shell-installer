#!/usr/bin/env python3
from pathlib import Path
import shlex

ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
I18N = (ROOT / "manager/style/I18n.qml").read_text(encoding="utf-8")
QMLDIR = (ROOT / "manager/style/qmldir").read_text(encoding="utf-8")
PREFLIGHT = (ROOT / "scripts/manager_preflight.sh").read_text(encoding="utf-8")
LAUNCHER = (ROOT / "manager.sh").read_text(encoding="utf-8")

assert "singleton I18n 1.0 I18n.qml" in QMLDIR
for variable in ("CAELESTIA_WEBAPPS_LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG"):
    assert f'Quickshell.env("{variable}")' in I18N
assert '/^de([_.@-]|$)/i.test(requestedLanguage)' in I18N
assert 'readonly property string language:' in I18N
assert 'return isGerman ? german : english' in I18N

# Built-in catalog comments are German legacy data. English mode deliberately
# uses the already existing genericName; user-authored descriptions are kept.
assert 'if (isGerman || app.source === "user")' in I18N
assert 'return app.genericName || app.comment || app.name' in I18N
assert "Style.I18n.appDescription(modelData)" in SHELL
assert "Style.I18n.appDescription(root.actionMenuApp)" in SHELL

for pair in (
    '("Empfohlen", "Featured")',
    '("Installiert", "Installed")',
    '("WebApp hinzufügen", "Add WebApp")',
    '("WebApp-Info", "WebApp info")',
    '("Applet-Einstellungen", "Applet settings")',
    '("Über", "About")',
    '("Abbrechen", "Cancel")',
    '("Deinstallieren", "Uninstall")',
    '("Keine passenden WebApps", "No matching WebApps")',
):
    assert f"Style.I18n.choose{pair}" in SHELL, pair

assert '"labelEn":"%s"' in PREFLIGHT
assert '"detailEn":"%s"' in PREFLIGHT
for line in PREFLIGHT.splitlines():
    if not line.startswith('emit "'):
        continue
    fields = shlex.split(line)
    assert len(fields) in (7, 8), (line, fields)

assert "CAELESTIA_WEBAPPS_LANGUAGE" in LAUNCHER
assert "Error: Quickshell was not found." in LAUNCHER
assert "Fehler: Quickshell wurde nicht gefunden." in LAUNCHER

for path in (ROOT / "manager").rglob("*.qml"):
    text = path.read_text(encoding="utf-8")
    assert "import qs." not in text, path
    assert "import Caelestia" not in text, path

print("PASS: Phase18.1 Manager locale selection and German/English UI contract")
