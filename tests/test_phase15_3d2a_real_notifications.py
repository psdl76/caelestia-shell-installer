#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLI = ROOT / "bin/caelestia-webapps"
WATCH = ROOT / "scripts/notification_watch.py"

spec = importlib.util.spec_from_file_location("notification_watch", WATCH)
assert spec and spec.loader
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

sample = '''method call time=1 sender=:1.28 -> destination=:1.11 serial=58 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=Notify\n   string "Firefox"\n   uint32 0\n   string ""\n   string "Carmen Seidl"\n   string "Okay 🥰"\n   array [\n      string "default"\n      string "Activate"\n   ]\n   array [\n      dict entry(\n         string "desktop-entry"\n         variant             string "whatsapp"\n      )\n      dict entry(\n         string "image-data"\n         variant             struct {\n               int32 96\n               array of bytes [\n                  01 02 03 ff\n               ]\n         }\n      )\n   ]\n   int32 -1\n'''
parser = mod.NotifyParser()
event = None
for line in sample.splitlines(True):
    event = parser.feed(line) or event
assert event is not None
assert event["desktopEntry"] == "whatsapp", event
assert event["summary"] == "Carmen Seidl", event
assert event["body"] == "Okay 🥰", event

with tempfile.TemporaryDirectory() as tmp:
    state = Path(tmp) / "caelestia-webapps/notification-events.json"
    state.parent.mkdir(parents=True)
    state.write_text(json.dumps({
        "version": 1,
        "updatedAt": 1787034977,
        "events": [{
            "id": "dbus-test-1",
            "appId": "whatsapp",
            "title": "Carmen Seidl",
            "text": "Okay 🥰",
            "timestamp": int(__import__('time').time()),
            "image": "",
            "actions": [],
            "source": "freedesktop-notify"
        }]
    }), encoding="utf-8")
    env = os.environ.copy()
    env["XDG_STATE_HOME"] = tmp
    env.pop("CAELESTIA_WEBAPPS_STATUS_DEMO", None)
    env.pop("CAELESTIA_WEBAPPS_STATUS_DEMO_APP", None)
    proc = subprocess.run([str(CLI), "status-feed", "whatsapp"], cwd=ROOT, env=env,
                          text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
    assert proc.returncode == 0, proc.stderr
    payload = json.loads(proc.stdout)["data"]
    assert payload["available"] is True, payload
    assert payload["kind"] == "notification", payload
    assert payload["state"]["count"] == 1, payload
    assert payload["state"]["title"] == "Carmen Seidl", payload
    assert payload["state"]["text"] == "Okay 🥰", payload
    assert payload["state"]["source"] == "freedesktop-notify", payload

print("Phase 15.3d.2a real notification source: PASS")
