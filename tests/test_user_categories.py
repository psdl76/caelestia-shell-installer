#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import stat
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
CLI = ROOT / "bin" / "caelestia-webapps"


def run(env: dict[str, str], *args: str, expected: int = 0) -> dict:
    proc = subprocess.run([str(CLI), *args], env=env, text=True, capture_output=True)
    if proc.returncode != expected:
        raise AssertionError(
            f"command {args} returned {proc.returncode}, expected {expected}\nstdout={proc.stdout}\nstderr={proc.stderr}"
        )
    return json.loads(proc.stdout)


with tempfile.TemporaryDirectory(prefix="caelestia-user-categories-") as raw:
    root = Path(raw)
    home = root / "home"
    config = root / "config"
    runtime = root / "runtime"
    home.mkdir()
    config.mkdir()
    runtime.mkdir()
    env = os.environ.copy()
    env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(config), "XDG_RUNTIME_DIR": str(runtime)})

    created = run(env, "user-category-create", json.dumps({"label": "Smart Home", "icon": "home"}))
    category = created["data"]["result"]["category"]
    assert category["id"] == "smart-home"
    assert category["deletable"] is True

    category_file = config / "caelestia-webapps" / "categories.json"
    stored = json.loads(category_file.read_text(encoding="utf-8"))
    assert stored == {
        "schemaVersion": 1,
        "categories": {"smart-home": {"icon": "home", "label": "Smart Home"}},
    }
    assert stat.S_IMODE(category_file.stat().st_mode) == 0o600
    assert stat.S_IMODE(category_file.parent.stat().st_mode) == 0o700

    listed = run(env, "list")["data"]
    assert not any(item["id"] == "smart-home" for item in listed["categories"])
    available = next(item for item in listed["availableCategories"] if item["id"] == "smart-home")
    assert available == {
        "id": "smart-home",
        "label": "Smart Home",
        "icon": "home",
        "source": "user",
        "count": 0,
        "deletable": True,
    }

    app_payload = {
        "id": "home-assistant",
        "name": "Home Assistant",
        "url": "https://example.invalid/",
        "category": "smart-home",
        "iconMode": "auto",
    }
    run(env, "user-create", json.dumps(app_payload))
    listed = run(env, "list")["data"]
    populated = next(item for item in listed["categories"] if item["id"] == "smart-home")
    assert populated["label"] == "Smart Home" and populated["count"] == 1
    app = next(item for item in listed["apps"] if item["id"] == "home-assistant")
    assert app["category"] == "smart-home"
    assert app["appletVisible"] is False
    assert app["appletShowBadge"] is False
    assert app["appletNotificationPreview"] is False
    assert app["specialWorkspace"] == ""
    assert next(item for item in listed["availableCategories"] if item["id"] == "smart-home")["deletable"] is False

    blocked = run(env, "user-category-delete", "smart-home", expected=30)
    assert blocked["error"]["code"] == "category_in_use"

    updated = run(env, "user-category-update", "smart-home", json.dumps({"label": "Mein Zuhause", "icon": "devices"}))
    assert updated["data"]["result"]["category"]["id"] == "smart-home"
    listed = run(env, "list")["data"]
    renamed = next(item for item in listed["availableCategories"] if item["id"] == "smart-home")
    assert renamed["label"] == "Mein Zuhause" and renamed["icon"] == "devices"
    app_conf = config / "caelestia-webapps" / "apps" / "home-assistant.conf"
    assert 'APP_CATALOG_CATEGORY=smart-home' in app_conf.read_text(encoding="utf-8")

    run(env, "user-delete", "home-assistant")
    installed = home / ".local/share/caelestia-webapps/apps/orphan-home/installed.conf"
    installed.parent.mkdir(parents=True)
    installed.write_text('APP_ID="orphan-home"\nAPP_CATALOG_CATEGORY="smart-home"\n', encoding="utf-8")
    blocked_orphan = run(env, "user-category-delete", "smart-home", expected=30)
    assert blocked_orphan["error"]["code"] == "category_in_use"
    installed.unlink()

    deleted = run(env, "user-category-delete", "smart-home")
    assert deleted["data"]["result"]["category"]["id"] == "smart-home"
    assert not any(item["id"] == "smart-home" for item in run(env, "list")["data"]["availableCategories"])

    for payload, code in (
        ({"label": "All", "icon": "home"}, "invalid_category_id"),
        ({"label": "Broken", "icon": "not-an-icon"}, "invalid_category_icon"),
        ({"label": "", "icon": "home"}, "invalid_category_name"),
    ):
        failed = run(env, "user-category-create", json.dumps(payload), expected=30)
        assert failed["error"]["code"] == code

print("PASS: user category create/list/use/rename/delete lifecycle")
