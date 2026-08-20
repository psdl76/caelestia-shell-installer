#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

with tempfile.TemporaryDirectory() as td:
    tmp = Path(td)
    (tmp / "data").mkdir()
    (tmp / "user").mkdir()
    catalog = tmp / "catalog.json"
    registry_a = tmp / "registry-a.json"
    registry_b = tmp / "registry-b.json"

    subprocess.run([
        "python3", str(ROOT / "scripts/generate_catalog.py"),
        str(ROOT / "apps"), str(tmp / "user"), str(tmp / "data"), str(catalog)
    ], check=True)
    subprocess.run(["python3", str(ROOT / "scripts/validate_catalog.py"), str(catalog)], check=True)
    subprocess.run(["python3", str(ROOT / "scripts/generate_applet_registry.py"), str(catalog), str(registry_a)], check=True)
    subprocess.run(["python3", str(ROOT / "scripts/generate_applet_registry.py"), str(catalog), str(registry_b)], check=True)
    assert registry_a.read_bytes() == registry_b.read_bytes(), "registry must be byte-deterministic"
    subprocess.run(["python3", str(ROOT / "scripts/validate_applet_registry.py"), str(catalog), str(registry_a)], check=True)

    data = json.loads(registry_a.read_text())
    assert data["schemaVersion"] == 1
    assert data["catalogSchemaVersion"] == 2
    assert len(data["apps"]) == 21
    ids = [app["id"] for app in data["apps"]]
    assert ids == sorted(ids)
    assert len(ids) == len(set(ids))
    assert all(app["defaultEnabled"] is False for app in data["apps"])
    assert sum(app["support"] == "supported" for app in data["apps"]) == 4
    assert sum(app["support"] == "experimental" for app in data["apps"]) == 17
    assert {app["adapter"] for app in data["apps"]} == {"notifications", "media", "mail", "calendar"}
    for expected in ("whatsapp", "google-messages", "youtube", "youtube-music"):
        assert expected in ids

    # Negative: a manually edited registry must fail exact projection validation.
    broken = json.loads(registry_a.read_text())
    broken["apps"][0]["capabilities"] = ["bogus"]
    broken_path = tmp / "registry-broken.json"
    broken_path.write_text(json.dumps(broken, indent=2) + "\n")
    bad = subprocess.run([
        "python3", str(ROOT / "scripts/validate_applet_registry.py"), str(catalog), str(broken_path)
    ], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert bad.returncode != 0
    assert "exact catalog projection" in bad.stderr

print("PASS: Phase16.3 registry1 deterministic catalog projection (21 applets)")

# Catalog lifecycle integration and stable CLI smoke test use a disposable HOME.
with tempfile.TemporaryDirectory() as home:
    env = {"HOME": home, "PATH": "/usr/bin:/bin", "XDG_RUNTIME_DIR": str(Path(home)/"run")}
    (Path(home)/".config/caelestia-webapps/apps").mkdir(parents=True)
    cli = subprocess.run([str(ROOT/"bin/caelestia-webapps"), "validate-applet-registry"], env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    payload = json.loads(cli.stdout)
    assert payload["ok"] is True and payload["data"]["consistent"] is True
    persisted = Path(home)/".local/share/caelestia-webapps/applet-registry.json"
    assert persisted.is_file()
    assert len(json.loads(persisted.read_text())["apps"]) == 21
