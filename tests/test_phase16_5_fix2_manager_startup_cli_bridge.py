#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
QML = (ROOT / "manager/shell.qml").read_text()
CATALOG_SH = (ROOT / "catalog.sh").read_text()
CLI = (ROOT / "bin/caelestia-webapps").read_text()

# Manager must no longer watch the persisted catalog directly.
assert 'FileView {\n        id: catalog' not in QML
assert 'catalog.reload()' not in QML
assert 'id: catalogProcess' in QML
assert '[root.projectRoot + "/bin/caelestia-webapps", "list"]' in QML
assert 'root.startupPreflightDone && root.startupCatalogDone && root.startupAppletDone' in QML
assert 'id: appletStateProcess' in QML and 'running: false' in QML
assert 'interval: 500' in QML

# catalog.sh read commands are read-only; rebuild is explicit.
pre_case = CATALOG_SH.split('case "$command_name" in', 1)[1]
assert 'rebuild)\n    acquire_mutation_lock "catalog-rebuild"' in pre_case
assert 'list)\n    require_persisted_catalog\n    acquire_read_lock "catalog-list"' in pre_case
assert 'json)\n    require_persisted_catalog\n    acquire_read_lock "catalog-json"' in pre_case
assert 'rebuild_catalog\ncase' not in CATALOG_SH
assert 'if command == "refresh":' in CLI
assert '[str(CATALOG_SCRIPT), "rebuild"]' in CLI

with tempfile.TemporaryDirectory() as td:
    home = Path(td)
    env = os.environ.copy()
    env.update({
        "HOME": str(home),
        "XDG_CONFIG_HOME": str(home / ".config"),
        "XDG_RUNTIME_DIR": str(home / "run"),
        "PATH": "/usr/bin:/bin",
    })
    (home / ".config/caelestia-webapps/apps").mkdir(parents=True)
    (home / "run").mkdir(parents=True)

    def run(*args: str) -> dict:
        proc = subprocess.run(
            [str(ROOT / "bin/caelestia-webapps"), *args],
            cwd=ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=True,
        )
        return json.loads(proc.stdout)

    # First CLI read bootstraps once when no persisted pair exists.
    first = run("list")
    assert first["ok"] is True and first["command"] == "list"
    catalog = home / ".local/share/caelestia-webapps/catalog.json"
    registry = home / ".local/share/caelestia-webapps/applet-registry.json"
    assert catalog.is_file() and registry.is_file()

    def fingerprint(path: Path) -> tuple[int, int, int, bytes]:
        st = path.stat()
        return st.st_ino, st.st_size, st.st_mtime_ns, path.read_bytes()

    cat_before = fingerprint(catalog)
    reg_before = fingerprint(registry)
    for command in [
        ("list",),
        ("runtime",),
        ("applet-state",),
        ("applet-entry", "youtube"),
    ]:
        payload = run(*command)
        assert payload["ok"] is True
        assert fingerprint(catalog) == cat_before, f"{command} rewrote catalog.json"
        assert fingerprint(registry) == reg_before, f"{command} rewrote applet-registry.json"

    # Explicit refresh is the writer and must leave a valid pair behind.
    time.sleep(0.01)
    refreshed = run("refresh")
    assert refreshed["ok"] is True and refreshed["command"] == "refresh"
    assert json.loads(catalog.read_text())["schemaVersion"] == 2
    assert json.loads(registry.read_text())["schemaVersion"] == 1
    assert fingerprint(catalog)[2] >= cat_before[2]

print("PASS: Phase16.5-fix2 read-only catalog lifecycle + manager CLI startup bridge")
