#!/usr/bin/env python3
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    subprocess.run(args, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def twice(script, action, path):
    run("python3", str(ROOT / "scripts" / script), action, str(path))
    first = path.read_bytes()
    run("python3", str(ROOT / "scripts" / script), action, str(path))
    second = path.read_bytes()
    assert first == second, f"{script} {action} changed output on second run"


with tempfile.TemporaryDirectory() as d:
    d = Path(d)
    status = d / "StatusIcons.qml"
    status.write_text('''import QtQuick\nimport QtQuick.Layouts\n\nItem {\n    id: root\n    property int spacing: 4\n    property color colour: "white"\n    ColumnLayout {\n        id: iconColumn\n        Repeater { model: [] }\n    }\n}\n''')
    twice("patch_bar.py", "install-status", status)
    assert status.read_text().count("BEGIN CAELESTIA-WEBAPPS STATUS ICONS") == 1

    pop = d / "Content.qml"
    pop.write_text('''import QtQuick\n\nItem {\n    id: root\n    Item {\n        id: content\n    }\n}\n''')
    twice("patch_bar.py", "install-popouts", pop)
    assert pop.read_text().count("BEGIN CAELESTIA-WEBAPPS POPOUTS") == 1

    nd = d / "NotifData.qml"
    nd.write_text('''import QtQuick\nQtObject {\n    property string appName\n    property var notification\n    property var locks: new Set()\n    function lock(item: Item): void { locks.add(item); }\n    function unlock(item: Item): void { locks.delete(item); }\n    Component.onCompleted: {\n        appName = notification.appName;\n    }\n}\n''')
    twice("patch_notifications.py", "install-notifdata", nd)
    assert nd.read_text().count("property string desktopEntry") == 1

    notifs = d / "Notifs.qml"
    notifs.write_text('''import QtQuick\nQtObject {\n    function save(n) {\n        return {\n                    appName: n.appName,\n        }\n    }\n}\n''')
    twice("patch_notifications.py", "install-notifs", notifs)
    assert notifs.read_text().count("desktopEntry: n.desktopEntry") == 1

print("PASS: QML/notification patchers are byte-stable on repeated install")
