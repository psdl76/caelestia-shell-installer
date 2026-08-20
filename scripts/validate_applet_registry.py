#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

REGISTRY_SCHEMA_VERSION = 1
CATALOG_SCHEMA_VERSION = 2


def project_independently(catalog: dict[str, Any]) -> dict[str, Any]:
    if catalog.get("schemaVersion") != CATALOG_SCHEMA_VERSION:
        raise ValueError(f"catalog schema must be v{CATALOG_SCHEMA_VERSION}")
    apps = catalog.get("apps")
    if not isinstance(apps, list):
        raise ValueError("catalog.apps must be a list")

    projected: list[dict[str, Any]] = []
    for app in apps:
        if not isinstance(app, dict):
            raise ValueError("catalog app must be an object")
        applet = app.get("applet")
        if not isinstance(applet, dict):
            raise ValueError(f"{app.get('id', '?')}: missing applet object")
        if applet.get("available") is not True:
            continue
        bridge = app.get("browserBridge")
        if not isinstance(bridge, dict):
            raise ValueError(f"{app.get('id', '?')}: missing browserBridge object")
        projected.append({
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
            "browserBridge": {"kind": bridge["kind"], "port": bridge["port"]},
            "icon": {
                "name": app["iconName"],
                "provider": app["iconProvider"],
                "id": app["iconId"],
            },
        })
    projected.sort(key=lambda item: item["id"])
    return {
        "schemaVersion": REGISTRY_SCHEMA_VERSION,
        "catalogSchemaVersion": CATALOG_SCHEMA_VERSION,
        "apps": projected,
    }


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: validate_applet_registry.py CATALOG REGISTRY", file=sys.stderr)
        return 2
    catalog_path = Path(sys.argv[1])
    registry_path = Path(sys.argv[2])
    try:
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
        actual = json.loads(registry_path.read_text(encoding="utf-8"))
        expected = project_independently(catalog)
    except (OSError, json.JSONDecodeError, ValueError, KeyError, TypeError) as exc:
        print(f"invalid applet registry: {exc}", file=sys.stderr)
        return 1

    if not isinstance(actual, dict):
        print("invalid applet registry: registry root must be an object", file=sys.stderr)
        return 1
    if actual.get("schemaVersion") != REGISTRY_SCHEMA_VERSION:
        print(f"invalid applet registry: schemaVersion must be {REGISTRY_SCHEMA_VERSION}", file=sys.stderr)
        return 1
    if actual.get("catalogSchemaVersion") != CATALOG_SCHEMA_VERSION:
        print(f"invalid applet registry: catalogSchemaVersion must be {CATALOG_SCHEMA_VERSION}", file=sys.stderr)
        return 1
    if actual != expected:
        expected_ids = [app["id"] for app in expected["apps"]]
        actual_apps = actual.get("apps") if isinstance(actual.get("apps"), list) else []
        actual_ids = [app.get("id") for app in actual_apps if isinstance(app, dict)]
        print("invalid applet registry: registry is not the exact catalog projection", file=sys.stderr)
        print(f"expected apps ({len(expected_ids)}): {', '.join(expected_ids)}", file=sys.stderr)
        print(f"actual apps   ({len(actual_ids)}): {', '.join(str(x) for x in actual_ids)}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
