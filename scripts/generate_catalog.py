#!/usr/bin/env python3

import json
import re
import shlex
import sys
from datetime import datetime, timezone
from pathlib import Path

from category_store import merged_categories

ASSIGN = re.compile(r'^([A-Z][A-Z0-9_]*)=(?:"(.*)"|\'(.*)\')$')


def parse_conf(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, raw_value = line.split("=", 1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key):
            continue
        try:
            parsed = shlex.split(raw_value, posix=True)
        except ValueError:
            continue
        if len(parsed) == 1:
            values[key] = parsed[0]
        elif raw_value == "":
            values[key] = ""
    return values


def as_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}



def split_semicolon_list(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(";") if item.strip()]


STATUS_TYPES = {
    "none",
    "notification",
    "activity",
    "media",
    "calendar",
    "tasks",
    "transfer",
    "deployment",
}

APPLET_ADAPTERS = {"none", "notifications", "media", "calendar", "mail"}
APPLET_SUPPORT = {"none", "experimental", "supported"}
APPLET_CAPABILITIES = {
    "notifications",
    "badge",
    "preview",
    "now_playing",
    "playback_controls",
    "artwork",
    "live_preview",
    "video_crop",
    "pin",
    "unread",
    "latest_mail",
    "next_event",
    "upcoming_events",
}
LEGACY_STATUS_TYPE = {
    "none": "none",
    "notifications": "notification",
    "mail": "notification",
    "media": "media",
    "calendar": "calendar",
}

def load_category_defaults(
    definitions_dir: Path, user_category_file: Path | None = None
) -> dict[str, dict[str, object]]:
    schema = definitions_dir.parent / "config" / "categories.json"
    return merged_categories(schema, user_category_file)



def collect_definitions(
    builtin_dir: Path, user_dir: Path
) -> list[tuple[Path, str]]:
    by_id: dict[str, tuple[Path, str]] = {}
    for source, directory in (("builtin", builtin_dir), ("user", user_dir)):
        if not directory.is_dir():
            continue
        for conf in sorted(directory.glob("*.conf")):
            definition = parse_conf(conf)
            app_id = definition.get("APP_ID", conf.stem)
            # A user definition may not shadow a built-in app. This keeps ownership
            # unambiguous and makes updates safe.
            if source == "user" and app_id in by_id and by_id[app_id][1] == "builtin":
                raise SystemExit(f"user app id shadows built-in app: {app_id}")
            by_id[app_id] = (conf, source)
    return [by_id[k] for k in sorted(by_id)]


def main() -> None:
    if len(sys.argv) == 4:
        # Backward-compatible generator contract used by older tests/tools.
        builtin_dir = Path(sys.argv[1])
        user_dir = builtin_dir.parent / ".no-user-apps"
        data_root = Path(sys.argv[2])
        output = Path(sys.argv[3])
        user_category_file = None
    elif len(sys.argv) == 5:
        builtin_dir = Path(sys.argv[1])
        user_dir = Path(sys.argv[2])
        data_root = Path(sys.argv[3])
        output = Path(sys.argv[4])
        user_category_file = None
    elif len(sys.argv) == 6:
        builtin_dir = Path(sys.argv[1])
        user_dir = Path(sys.argv[2])
        data_root = Path(sys.argv[3])
        output = Path(sys.argv[4])
        user_category_file = Path(sys.argv[5])
    else:
        raise SystemExit(
            "usage: generate_catalog.py BUILTIN_DEF_DIR [USER_DEF_DIR] DATA_ROOT OUTPUT [USER_CATEGORY_JSON]"
        )
    categories = load_category_defaults(builtin_dir, user_category_file)
    apps: list[dict[str, object]] = []

    for conf, source in collect_definitions(builtin_dir, user_dir):
        definition = parse_conf(conf)
        app_id = definition.get("APP_ID", conf.stem)
        category_name = definition.get("APP_CATALOG_CATEGORY", "")
        app_categories = split_semicolon_list(definition.get("APP_CATALOG_CATEGORIES_LIST", ""))
        if not app_categories:
            app_categories = [category_name]
        elif category_name not in app_categories:
            app_categories.insert(0, category_name)
        if category_name not in categories:
            raise SystemExit(
                f"{conf.name}: unknown APP_CATALOG_CATEGORY={category_name!r}; "
                f"allowed: {', '.join(sorted(categories))}"
            )
        for extra_category in app_categories:
            if extra_category not in categories:
                raise SystemExit(
                    f"{conf.name}: unknown APP_CATALOG_CATEGORIES_LIST entry={extra_category!r}; "
                    f"allowed: {', '.join(sorted(categories))}"
                )
        category = categories[category_name]
        installed = (data_root / "apps" / app_id / "installed.conf").is_file()

        provider = definition.get("APP_PROVIDER", "custom" if source == "user" else "unknown")
        tags = split_semicolon_list(definition.get("APP_TAGS", ""))
        featured = as_bool(definition.get("APP_FEATURED"), False)
        # Phase 16.1: app definitions use one final applet/capability model.
        # statusIntegration remains a generated compatibility mirror for Phase 15
        # consumers and is no longer authored in app .conf files.
        applet_available = as_bool(definition.get("APPLET_AVAILABLE"), False)
        applet_default_enabled = as_bool(
            definition.get("APPLET_DEFAULT_ENABLED"), False
        )
        applet_adapter = definition.get("APPLET_ADAPTER", "none").strip() or "none"
        applet_support = definition.get("APPLET_SUPPORT", "none").strip() or "none"
        applet_capabilities = split_semicolon_list(
            definition.get("APPLET_CAPABILITIES", "")
        )
        applet_match_hosts = split_semicolon_list(
            definition.get("APPLET_MATCH_HOSTS", "")
        )

        if applet_adapter not in APPLET_ADAPTERS:
            raise SystemExit(
                f"{conf.name}: unknown APPLET_ADAPTER={applet_adapter!r}; "
                f"allowed: {', '.join(sorted(APPLET_ADAPTERS))}"
            )
        if applet_support not in APPLET_SUPPORT:
            raise SystemExit(
                f"{conf.name}: unknown APPLET_SUPPORT={applet_support!r}; "
                f"allowed: {', '.join(sorted(APPLET_SUPPORT))}"
            )
        unknown_caps = sorted(set(applet_capabilities) - APPLET_CAPABILITIES)
        if unknown_caps:
            raise SystemExit(
                f"{conf.name}: unknown APPLET_CAPABILITIES: {', '.join(unknown_caps)}"
            )
        if applet_adapter == "none":
            if applet_available or applet_default_enabled or applet_capabilities:
                raise SystemExit(
                    f"{conf.name}: APPLET_ADAPTER=none cannot be available/default-enabled "
                    "or declare capabilities"
                )
            applet_support = "none"
        else:
            if not applet_available:
                raise SystemExit(
                    f"{conf.name}: APPLET_ADAPTER={applet_adapter} requires APPLET_AVAILABLE=true"
                )
            if applet_support == "none":
                raise SystemExit(
                    f"{conf.name}: available applet requires APPLET_SUPPORT=experimental|supported"
                )

        status_type = LEGACY_STATUS_TYPE[applet_adapter]
        status_recommended = applet_default_enabled
        status_capabilities = list(applet_capabilities)
        icon_name = definition.get("ICON_NAME", app_id)
        matches = [
            item.strip()
            for item in definition.get(
                "NOTIFICATION_MATCH", definition.get("APP_NAME", app_id)
            ).split("|")
            if item.strip()
        ]

        local_icon_raw = definition.get("ICON_LOCAL_FILE", "")
        local_icon = ""
        if local_icon_raw:
            if local_icon_raw.startswith("$ROOT_DIR/"):
                local_icon = str(builtin_dir.parent / local_icon_raw[len("$ROOT_DIR/"):])
            else:
                local_icon = local_icon_raw

        installed_icon = str(
            Path.home()
            / ".local/share/icons/hicolor/scalable/apps"
            / f"{icon_name}.svg"
        )
        icon_url = definition.get("ICON_URL", "")
        icon_mode = definition.get("APP_ICON_MODE", "")
        if not icon_mode:
            icon_mode = "local" if local_icon else ("auto" if icon_url == f"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/{app_id}.svg" else "url")
        store_cache = Path.home() / ".cache/caelestia-webapps/store-icons-v6"
        store_svg = store_cache / f"{icon_name}.svg"
        store_png = store_cache / f"{icon_name}.png"
        store_webp = store_cache / f"{icon_name}.webp"
        # The google-gemini SVG is a known Qt/Quickshell UI regression. Dashboard
        # Icons also publishes an equivalent generated PNG, which renders reliably.
        # Keep the special case presentation-only; installation/runtime semantics
        # stay unchanged.
        if app_id == "gemini" and store_png.is_file():
            store_icon = str(store_png)
        elif store_svg.is_file():
            store_icon = str(store_svg)
        elif store_png.is_file():
            store_icon = str(store_png)
        elif store_webp.is_file():
            store_icon = str(store_webp)
        else:
            store_icon = ""

        apps.append(
            {
                "id": app_id,
                "name": definition.get("APP_NAME", app_id),
                "genericName": definition.get("APP_GENERIC_NAME", "Web Application"),
                "comment": definition.get("APP_COMMENT", ""),
                "url": definition.get("APP_URL", ""),
                "category": category_name,
                "categories": app_categories,
                "provider": provider,
                "tags": tags,
                "featured": featured,
                "applet": {
                    "available": applet_available,
                    "defaultEnabled": applet_default_enabled,
                    "adapter": applet_adapter,
                    "support": applet_support,
                    "capabilities": applet_capabilities,
                    "matchHosts": applet_match_hosts,
                },
                "statusIntegration": {
                    "type": status_type,
                    "recommended": status_recommended,
                    "capabilities": status_capabilities,
                },
                "installed": installed,
                "source": source,
                "ownership": {
                    "owner": "user" if source == "user" else "package",
                    "definitionMutable": source == "user",
                    "survivesUpgrade": source == "user",
                    "removableFromCatalog": source == "user",
                },
                "capabilities": {
                    "launch": True,
                    "setup": True,
                    "install": True,
                    "repair": True,
                    "uninstall": True,
                    "edit": source == "user",
                },
                "windowClass": definition.get("WINDOW_CLASS", app_id),
                "browserBridge": {
                    "port": int(definition.get("BROWSER_BRIDGE_PORT", "0") or 0),
                    "kind": "webdriver-bidi" if definition.get("BROWSER_BRIDGE_PORT", "") else "none",
                },
                "iconName": icon_name,
                "iconProvider": definition.get("ICON_PROVIDER", ""),
                "iconId": definition.get("ICON_ID", icon_name),
                "icon": installed_icon,
                "iconLocal": local_icon,
                "iconUrl": icon_url,
                "iconMode": icon_mode,
                "iconStore": store_icon,
                "launcher": str(Path.home() / ".local/bin" / f"caelestia-webapp-{app_id}"),
                "setupLauncher": str(
                    Path.home() / ".local/bin" / f"caelestia-webapp-{app_id}-setup"
                ),
                "notificationMatch": (
                    matches[0] if matches else definition.get("APP_NAME", app_id)
                ),
                "notificationMatches": matches,
                "specialWorkspace": str(category.get("hyprSharedWorkspace", "")),
                "appletVisible": bool(category.get("appletVisible", False)),
                "appletShowBadge": bool(category.get("appletShowBadge", False)),
                "appletNotificationPreview": bool(
                    category.get("appletNotificationPreview", False)
                ),
            }
        )

    category_counts: dict[str, int] = {}
    for app in apps:
        for category_id in app.get("categories", [app.get("category", "")]):
            category_id = str(category_id)
            category_counts[category_id] = category_counts.get(category_id, 0) + 1

    catalog_categories = [
        {
            "id": category_id,
            "label": str(category.get("label", category_id)),
            "count": category_counts.get(category_id, 0),
            "order": int(category.get("order", 100)),
        }
        for category_id, category in sorted(
            categories.items(),
            key=lambda item: (
                int(item[1].get("order", 100)),
                str(item[1].get("label", item[0])).casefold(),
                item[0],
            ),
        )
        if category_counts.get(category_id, 0) > 0
    ]

    existing = None
    if output.is_file():
        try:
            existing = json.loads(output.read_text())
        except (json.JSONDecodeError, OSError):
            existing = None

    if (
        isinstance(existing, dict)
        and existing.get("schemaVersion") == 2
        and existing.get("apps") == apps
        and existing.get("categories") == catalog_categories
    ):
        return

    payload = {
        "schemaVersion": 2,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "categories": catalog_categories,
        "apps": apps,
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    temporary.replace(output)


if __name__ == "__main__":
    main()
