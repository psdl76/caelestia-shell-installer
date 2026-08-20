#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REGISTRY_SCHEMA_VERSION = 1
CATALOG_SCHEMA_VERSION = 2


def project_app(app: dict[str, Any]) -> dict[str, Any]:
    applet = app["applet"]
    return {
        "id": app["id"],
        "name": app["name"],
        "source": app["source"],
        "adapter": applet["adapter"],
        "support": applet["support"],
        "defaultEnabled": applet["defaultEnabled"],
        "capabilities": list(applet["capabilities"]),
        "matchHosts": list(applet["matchHosts"]),
        "windowClass": app["windowClass"],
        "notificationMatches": list(app["notificationMatches"]),
        "browserBridge": {
            "kind": app["browserBridge"]["kind"],
            "port": app["browserBridge"]["port"],
        },
        "icon": {
            "name": app["iconName"],
            "provider": app["iconProvider"],
            "id": app["iconId"],
        },
    }


def generate_registry(catalog: dict[str, Any]) -> dict[str, Any]:
    if catalog.get("schemaVersion") != CATALOG_SCHEMA_VERSION:
        raise ValueError(f"catalog schema must be v{CATALOG_SCHEMA_VERSION}")
    apps = catalog.get("apps")
    if not isinstance(apps, list):
        raise ValueError("catalog.apps must be a list")

    projected = [
        project_app(app)
        for app in apps
        if isinstance(app, dict)
        and isinstance(app.get("applet"), dict)
        and app["applet"].get("available") is True
    ]
    projected.sort(key=lambda app: app["id"])

    return {
        "schemaVersion": REGISTRY_SCHEMA_VERSION,
        "catalogSchemaVersion": CATALOG_SCHEMA_VERSION,
        "apps": projected,
    }


def main() -> int:
    if len(sys.argv) not in {2, 3}:
        print("usage: generate_applet_registry.py CATALOG [OUTPUT]", file=sys.stderr)
        return 2
    catalog_path = Path(sys.argv[1])
    output = Path(sys.argv[2]) if len(sys.argv) == 3 else None
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        registry = generate_registry(catalog)
    except (OSError, json.JSONDecodeError, ValueError, KeyError, TypeError) as exc:
        print(f"cannot generate applet registry: {exc}", file=sys.stderr)
        return 1

    text = json.dumps(registry, indent=2, ensure_ascii=False) + "\n"
    if output is None:
        sys.stdout.write(text)
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        temporary = output.with_suffix(output.suffix + ".tmp")
        temporary.write_text(text, encoding="utf-8")
        temporary.replace(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
