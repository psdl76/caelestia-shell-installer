#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path

PLUGIN_ID = "caelestia_webapps/webapps"

parser = argparse.ArgumentParser()
parser.add_argument("state", choices=["on", "off"])
args = parser.parse_args()

config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
path = config_home / "caelestia" / "plugins.json"
path.parent.mkdir(parents=True, exist_ok=True)

if path.exists():
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise SystemExit(f"Refusing to overwrite malformed {path}: {exc}")
    if not isinstance(data, dict):
        raise SystemExit(f"Refusing to overwrite non-object JSON in {path}")
else:
    data = {}

enabled = data.get("enabled", [])
if not isinstance(enabled, list) or not all(isinstance(x, str) for x in enabled):
    raise SystemExit(f"Invalid 'enabled' field in {path}")

if args.state == "on":
    if PLUGIN_ID not in enabled:
        enabled.append(PLUGIN_ID)
else:
    enabled = [x for x in enabled if x != PLUGIN_ID]

data["enabled"] = enabled
data.setdefault("path", [])
data.setdefault("settings", {})

tmp = path.with_suffix(".json.tmp")
tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
tmp.replace(path)

print(f"{PLUGIN_ID}: {'enabled' if args.state == 'on' else 'disabled'}")
print(path)
