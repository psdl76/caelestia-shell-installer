#!/usr/bin/env python3
from pathlib import Path


root = Path(__file__).resolve().parents[1]
qml = (root / "manager/shell.qml").read_text(encoding="utf-8")

required = [
    'apps = (parsed.apps || []).concat(parsed.orphanInstallations || [])',
    'if (app.orphaned === true)',
    '"orphan-uninstall"',
    '"orphan-uninstall-close"',
    '"orphan-restore"',
    'Benutzer-WebApp wiederherstellen',
    'Restore custom WebApp',
    'Verwaiste Installation bereinigen',
    'Clean up orphaned installation',
    'Verwaiste Installation',
    'Wiederherstellung',
]
for marker in required:
    assert marker in qml, f"missing Manager orphan-recovery contract: {marker}"

orphan_branch = qml.index('if (app.orphaned === true)', qml.index('function actionMenuEntries'))
normal_entries = qml.index('const entries = []', orphan_branch)
assert 'return recoveryEntries' in qml[orphan_branch:normal_entries]
assert 'id: "restore"' in qml[orphan_branch:normal_entries]
assert 'id: "remove"' in qml[orphan_branch:normal_entries]

print("PASS: Manager exposes safe restore plus one explicit destructive orphan action")
