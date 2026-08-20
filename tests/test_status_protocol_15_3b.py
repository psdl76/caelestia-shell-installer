#!/usr/bin/env python3
import json
import os
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
cli = root / "bin" / "caelestia-webapps"

def run(*args, env=None):
    e = os.environ.copy()
    if env:
        e.update(env)
    p = subprocess.run([str(cli), *args], cwd=root, env=e, text=True,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert p.returncode == 0, (p.returncode, p.stdout, p.stderr)
    return json.loads(p.stdout)

base = run("status-feed", "whatsapp")
assert base["apiVersion"] == 1
assert base["ok"] is True
assert base["command"] == "status-feed"
s = base["data"]
assert s["protocolVersion"] == 1
assert s["appId"] == "whatsapp"
assert s["kind"] == "notification"
assert s["available"] is False
assert s["state"] == {}
assert s["capabilities"] == ["badge", "preview"]

notif = run("status-feed", "whatsapp", env={
    "CAELESTIA_WEBAPPS_STATUS_DEMO": "notification",
    "CAELESTIA_WEBAPPS_STATUS_DEMO_APP": "whatsapp",
})["data"]
assert notif["available"] is True
assert notif["kind"] == "notification"
assert notif["state"]["count"] >= 1
assert notif["state"]["title"]
assert notif["state"]["text"]
assert notif["capabilities"] == ["badge", "preview"]

media = run("status-feed", "whatsapp", env={
    "CAELESTIA_WEBAPPS_STATUS_DEMO": "media",
    "CAELESTIA_WEBAPPS_STATUS_DEMO_APP": "whatsapp",
})["data"]
assert media["available"] is True
assert media["kind"] == "media"
assert media["state"]["playing"] is True
assert media["state"]["progress"] == 0.42
assert media["capabilities"] == ["now_playing", "playback_controls"]

all_payload = run("status-feed", env={
    "CAELESTIA_WEBAPPS_STATUS_DEMO": "notification",
    "CAELESTIA_WEBAPPS_STATUS_DEMO_APP": "whatsapp",
})["data"]
assert all_payload["protocolVersion"] == 1
assert isinstance(all_payload["statuses"], list)
wa = next(x for x in all_payload["statuses"] if x["appId"] == "whatsapp")
assert wa["available"] is True

qml = (root / "integrations/caelestia/plugin/WebAppsPopout.qml").read_text()
assert 'root.cliCommand(["status-feed"])' in qml
assert 'statusData.kind === "notification"' in qml
assert 'statusData.kind === "media"' in qml
assert 'modelData.id === "whatsapp"' not in qml
assert 'modelData.id === "youtube"' not in qml
assert 'modelData.id === "gmail"' not in qml

print("Phase 15.3b runtime status protocol/generic renderer: PASS")
