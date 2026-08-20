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

notif = run("status-feed", "whatsapp", env={
    "CAELESTIA_WEBAPPS_STATUS_DEMO": "notification",
    "CAELESTIA_WEBAPPS_STATUS_DEMO_APP": "whatsapp",
})["data"]
assert notif["protocolVersion"] == 1
assert notif["kind"] == "notification"
assert notif["available"] is True
state = notif["state"]
assert state["count"] == 5
assert state["title"] == state["items"][0]["title"]
assert state["text"] == state["items"][0]["text"]
assert len(state["items"]) == 3
for item in state["items"]:
    assert set(["id", "title", "text", "timestamp", "image", "actions"]).issubset(item)
    assert isinstance(item["actions"], list)

qml = (root / "integrations/caelestia/plugin/GenericStatusPopout.qml").read_text()
assert "notificationItems" in qml
assert "root.notificationItems.slice(0, 3)" in qml
assert 'text: "+ " + root.hiddenNotificationCount + " weitere"' in qml
assert "root.notificationItems.length === 0" in qml  # legacy v1 fallback
assert 'appId === "whatsapp"' not in qml
assert 'appId === "google-messages"' not in qml

central = (root / "integrations/caelestia/plugin/WebAppsPopout.qml").read_text()
assert "Array.isArray(stateData.items)" in central
assert "items[0]" in central

print("Phase 15.3d.1 multi-event notification protocol/generic popout: PASS")
