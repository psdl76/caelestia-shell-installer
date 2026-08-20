#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 2
APPLET_ADAPTERS = {"none", "notifications", "media", "calendar", "mail"}
APPLET_SUPPORT = {"none", "experimental", "supported"}
APPLET_CAPABILITIES = {
    "notifications", "badge", "preview",
    "now_playing", "playback_controls", "artwork", "live_preview", "video_crop", "pin",
    "unread", "latest_mail", "next_event", "upcoming_events",
}
ADAPTER_CAPABILITIES = {
    "none": set(),
    "notifications": {"notifications", "badge", "preview"},
    "media": {"now_playing", "playback_controls", "artwork", "live_preview", "video_crop", "pin"},
    "mail": {"unread", "latest_mail"},
    "calendar": {"next_event", "upcoming_events"},
}


class CatalogError(ValueError):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise CatalogError(message)


def require_type(value: Any, expected: type, path: str) -> None:
    require(isinstance(value, expected), f"{path}: expected {expected.__name__}")


def validate_catalog(data: Any) -> dict[str, Any]:
    require_type(data, dict, "$catalog")
    require(data.get("schemaVersion") == SCHEMA_VERSION,
            f"schemaVersion: expected {SCHEMA_VERSION}")
    require_type(data.get("generatedAt"), str, "generatedAt")
    require_type(data.get("categories"), list, "categories")
    require_type(data.get("apps"), list, "apps")

    categories: list[dict[str, Any]] = data["categories"]
    apps: list[dict[str, Any]] = data["apps"]

    category_ids: set[str] = set()
    category_counts: dict[str, int] = {}
    previous_order: int | None = None
    for index, category in enumerate(categories):
        path = f"categories[{index}]"
        require_type(category, dict, path)
        for key, typ in (("id", str), ("label", str), ("count", int), ("order", int)):
            require_type(category.get(key), typ, f"{path}.{key}")
        category_id = category["id"]
        require(bool(category_id), f"{path}.id: must not be empty")
        require(category_id not in category_ids, f"{path}.id: duplicate {category_id!r}")
        require(category["count"] > 0, f"{path}.count: populated categories must be > 0")
        if previous_order is not None:
            require(category["order"] >= previous_order,
                    f"{path}.order: categories must be sorted by order")
        previous_order = category["order"]
        category_ids.add(category_id)
        category_counts[category_id] = 0

    app_ids: set[str] = set()
    required_string_fields = (
        "id", "name", "genericName", "comment", "url", "category", "provider",
        "windowClass", "iconName", "iconProvider", "iconId", "icon", "iconLocal", "iconUrl",
        "iconStore", "launcher", "setupLauncher", "notificationMatch",
        "specialWorkspace", "source",
    )
    required_bool_fields = (
        "installed", "appletVisible", "appletShowBadge",
        "appletNotificationPreview",
    )
    capability_fields = ("launch", "setup", "install", "repair", "uninstall")

    for index, app in enumerate(apps):
        path = f"apps[{index}]"
        require_type(app, dict, path)
        for key in required_string_fields:
            require_type(app.get(key), str, f"{path}.{key}")
        for key in required_bool_fields:
            require_type(app.get(key), bool, f"{path}.{key}")
        require_type(app.get("notificationMatches"), list, f"{path}.notificationMatches")
        require(all(isinstance(item, str) for item in app["notificationMatches"]),
                f"{path}.notificationMatches: expected strings")
        require_type(app.get("categories"), list, f"{path}.categories")
        require(all(isinstance(item, str) and item for item in app["categories"]),
                f"{path}.categories: expected non-empty strings")
        require(app["category"] in app["categories"],
                f"{path}.categories: must include primary category")
        require_type(app.get("tags"), list, f"{path}.tags")
        require(all(isinstance(item, str) and item for item in app["tags"]),
                f"{path}.tags: expected non-empty strings")
        require_type(app.get("featured"), bool, f"{path}.featured")

        require_type(app.get("applet"), dict, f"{path}.applet")
        applet = app["applet"]
        require_type(applet.get("available"), bool, f"{path}.applet.available")
        require_type(applet.get("defaultEnabled"), bool, f"{path}.applet.defaultEnabled")
        require_type(applet.get("adapter"), str, f"{path}.applet.adapter")
        require(applet["adapter"] in APPLET_ADAPTERS,
                f"{path}.applet.adapter: unsupported adapter")
        require_type(applet.get("support"), str, f"{path}.applet.support")
        require(applet["support"] in APPLET_SUPPORT,
                f"{path}.applet.support: unsupported support state")
        require_type(applet.get("capabilities"), list, f"{path}.applet.capabilities")
        require(all(isinstance(item, str) and item for item in applet["capabilities"]),
                f"{path}.applet.capabilities: expected non-empty strings")
        unknown_applet_caps = sorted(set(applet["capabilities"]) - APPLET_CAPABILITIES)
        require(not unknown_applet_caps,
                f"{path}.applet.capabilities: unsupported {unknown_applet_caps}")
        invalid_adapter_caps = sorted(set(applet["capabilities"]) - ADAPTER_CAPABILITIES[applet["adapter"]])
        require(not invalid_adapter_caps,
                f"{path}.applet.capabilities: {invalid_adapter_caps} invalid for adapter {applet['adapter']!r}")
        require(len(applet["capabilities"]) == len(set(applet["capabilities"])),
                f"{path}.applet.capabilities: duplicates are not allowed")
        require_type(applet.get("matchHosts"), list, f"{path}.applet.matchHosts")
        require(all(isinstance(item, str) and item for item in applet["matchHosts"]),
                f"{path}.applet.matchHosts: expected non-empty strings")
        require(len(applet["matchHosts"]) == len(set(applet["matchHosts"])),
                f"{path}.applet.matchHosts: duplicates are not allowed")
        if applet["adapter"] == "none":
            require(not applet["available"], f"{path}.applet: none cannot be available")
            require(not applet["defaultEnabled"], f"{path}.applet: none cannot be default-enabled")
            require(applet["support"] == "none", f"{path}.applet: none requires support=none")
            require(not applet["capabilities"], f"{path}.applet: none cannot declare capabilities")
        else:
            require(applet["available"], f"{path}.applet: adapter requires available=true")
            require(not applet["defaultEnabled"], f"{path}.applet: core catalog applets default to disabled")
            require(applet["support"] in {"experimental", "supported"},
                    f"{path}.applet: available adapter requires support state")
            require(bool(applet["capabilities"]), f"{path}.applet: available adapter requires capabilities")
            if applet["adapter"] == "media":
                require(bool(applet["matchHosts"]), f"{path}.applet: media adapter requires matchHosts")
            else:
                require(not applet["matchHosts"], f"{path}.applet: only media adapter may currently use matchHosts")

        require_type(app.get("statusIntegration"), dict, f"{path}.statusIntegration")
        status = app["statusIntegration"]
        require_type(status.get("type"), str, f"{path}.statusIntegration.type")
        require(status["type"] in {"none", "notification", "activity", "media", "calendar", "tasks", "transfer", "deployment"},
                f"{path}.statusIntegration.type: unsupported type")
        require_type(status.get("recommended"), bool, f"{path}.statusIntegration.recommended")
        require_type(status.get("capabilities"), list, f"{path}.statusIntegration.capabilities")
        require(all(isinstance(item, str) and item for item in status["capabilities"]),
                f"{path}.statusIntegration.capabilities: expected non-empty strings")
        if status["type"] == "none":
            require(not status["recommended"], f"{path}.statusIntegration: none cannot be recommended")
            require(not status["capabilities"], f"{path}.statusIntegration: none cannot declare capabilities")
        require_type(app.get("capabilities"), dict, f"{path}.capabilities")
        for key in capability_fields:
            require_type(app["capabilities"].get(key), bool, f"{path}.capabilities.{key}")
        if "edit" in app["capabilities"]:
            require_type(app["capabilities"].get("edit"), bool, f"{path}.capabilities.edit")

        app_id = app["id"]
        require(bool(app_id), f"{path}.id: must not be empty")
        require(app_id not in app_ids, f"{path}.id: duplicate {app_id!r}")
        app_ids.add(app_id)
        require(app["category"] in category_ids,
                f"{path}.category: unknown category {app['category']!r}")
        for category_id in app["categories"]:
            require(category_id in category_ids,
                    f"{path}.categories: unknown category {category_id!r}")
            category_counts[category_id] += 1
        require(app["source"] in {"builtin", "user"},
                f"{path}.source: expected builtin or user")

    for category in categories:
        require(category["count"] == category_counts[category["id"]],
                f"category {category['id']!r}: count mismatch")

    return data


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_catalog.py CATALOG", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
        validate_catalog(data)
    except (OSError, json.JSONDecodeError, CatalogError) as exc:
        print(f"invalid catalog: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
