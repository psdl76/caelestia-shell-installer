#!/usr/bin/env python3
from pathlib import Path
import shutil
import sys

config_root = Path.home() / ".config/quickshell/caelestia-plugin-test"
if len(sys.argv) > 1:
    config_root = Path(sys.argv[1]).expanduser()

targets = [
    config_root / "modules/bar/Bar.qml",
    config_root / "modules/drawers/Interactions.qml",
]

for target in targets:
    patterns = [
        target.name + ".before-webapps-pin-fix6-*",
        target.name + ".before-webapps-pin-fix5b-*",
        target.name + ".before-webapps-pin-v3-*",
        target.name + ".before-webapps-pin-v2-*",
        target.name + ".before-webapps-pin-*",
    ]
    backups = []
    for pattern in patterns:
        backups.extend(target.parent.glob(pattern))
    backups = sorted(set(backups))

    if not backups:
        print(f"WARN: no backup found for {target}")
        continue

    source = backups[-1]
    shutil.copy2(source, target)
    print(f"Restored: {target}")
    print(f"From    : {source}")
