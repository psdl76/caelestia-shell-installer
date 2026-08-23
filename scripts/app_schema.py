#!/usr/bin/env python3
import json
import re
import shlex
import sys
from pathlib import Path

from category_store import merged_categories

ASSIGN = re.compile(r'^([A-Z][A-Z0-9_]*)=(?:"(.*)"|\'(.*)\')$')
CATEGORY_OWNED = {
    "APPLET_VISIBLE",
    "APPLET_SHOW_BADGE",
    "APPLET_NOTIFICATION_PREVIEW",
    "HYPR_SHARED_TAG",
    "HYPR_SHARED_OWNER",
    "HYPR_SHARED_WORKSPACE",
    "HYPR_SHARED_LOCAL_DECL",
    "HYPR_SHARED_RULE_MARKER",
    "HYPR_SHARED_CREATE_TAG",
    "HYPR_SHARED_KEYBIND",
}

APPLET_ADAPTERS = {"none", "notifications", "media", "calendar", "mail"}
APPLET_SUPPORT = {"none", "experimental", "supported"}
APPLET_CAPABILITIES = {
    "notifications", "badge", "preview",
    "now_playing", "playback_controls", "artwork", "live_preview", "video_crop", "pin",
    "unread", "latest_mail", "next_event", "upcoming_events",
}


def parse_conf(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = ASSIGN.match(line)
        if m:
            values[m.group(1)] = m.group(2) if m.group(2) is not None else m.group(3)
    return values


def load_categories(path: Path) -> dict[str, dict[str, object]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schemaVersion") != 1 or not isinstance(data.get("categories"), dict):
        raise SystemExit(f"Ungültiges Kategorie-Schema: {path}")
    return data["categories"]


def normalized_defaults(category: dict[str, object]) -> dict[str, str]:
    mapping = {
        "APPLET_VISIBLE": category.get("appletVisible", False),
        "APPLET_SHOW_BADGE": category.get("appletShowBadge", False),
        "APPLET_NOTIFICATION_PREVIEW": category.get("appletNotificationPreview", False),
        "HYPR_SHARED_TAG": category.get("hyprSharedTag", ""),
        "HYPR_SHARED_OWNER": category.get("hyprSharedOwner", ""),
        "HYPR_SHARED_WORKSPACE": category.get("hyprSharedWorkspace", ""),
        "HYPR_SHARED_LOCAL_DECL": category.get("hyprSharedLocalDecl", ""),
        "HYPR_SHARED_RULE_MARKER": category.get("hyprSharedRuleMarker", ""),
        "HYPR_SHARED_CREATE_TAG": category.get("hyprSharedCreateTag", ""),
        "HYPR_SHARED_KEYBIND": category.get("hyprSharedKeybind", ""),
    }
    out: dict[str, str] = {}
    for key, value in mapping.items():
        if isinstance(value, bool):
            out[key] = "true" if value else "false"
        else:
            out[key] = str(value or "")
    return out


def emit_shell(defaults: dict[str, str]) -> None:
    for key, value in defaults.items():
        print(f"{key}={shlex.quote(value)}")


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: app_schema.py defaults|validate CATEGORY_JSON [CATEGORY|CONF]")
    action = sys.argv[1]
    category_file = Path(sys.argv[2])
    user_category_file = Path(sys.argv[3]) if action == "shell-all" and len(sys.argv) == 4 else None
    categories = merged_categories(category_file, user_category_file)

    if action == "shell-all":
        fields = {
            "APPLET_VISIBLE": "appletVisible",
            "APPLET_SHOW_BADGE": "appletShowBadge",
            "APPLET_NOTIFICATION_PREVIEW": "appletNotificationPreview",
            "HYPR_SHARED_TAG": "hyprSharedTag",
            "HYPR_SHARED_OWNER": "hyprSharedOwner",
            "HYPR_SHARED_WORKSPACE": "hyprSharedWorkspace",
            "HYPR_SHARED_LOCAL_DECL": "hyprSharedLocalDecl",
            "HYPR_SHARED_RULE_MARKER": "hyprSharedRuleMarker",
            "HYPR_SHARED_CREATE_TAG": "hyprSharedCreateTag",
            "HYPR_SHARED_KEYBIND": "hyprSharedKeybind",
        }
        for var, field in fields.items():
            print(f"declare -gA CATEGORY_{var}=()")
            for name, definition in categories.items():
                value = definition.get(field, False if field.startswith("applet") else "")
                if isinstance(value, bool):
                    value = "true" if value else "false"
                print(f"CATEGORY_{var}[{shlex.quote(name)}]={shlex.quote(str(value or ''))}")
        print("declare -ga APP_CATALOG_CATEGORIES=(" + " ".join(shlex.quote(x) for x in sorted(categories)) + ")")
        return

    if action == "defaults":
        if len(sys.argv) != 4:
            raise SystemExit("usage: app_schema.py defaults CATEGORY_JSON CATEGORY")
        name = sys.argv[3]
        if name not in categories:
            raise SystemExit(f"Unbekannte APP_CATALOG_CATEGORY: {name}")
        emit_shell(normalized_defaults(categories[name]))
        return

    if action == "validate":
        if len(sys.argv) != 4:
            raise SystemExit("usage: app_schema.py validate CATEGORY_JSON CONF")
        conf = Path(sys.argv[3])
        values = parse_conf(conf)
        category = values.get("APP_CATALOG_CATEGORY", "")
        errors: list[str] = []
        if category not in categories:
            errors.append(
                f"APP_CATALOG_CATEGORY={category!r} ist unbekannt. Erlaubt: {', '.join(sorted(categories))}"
            )

        applet_available = values.get("APPLET_AVAILABLE", "false").lower() == "true"
        applet_default = values.get("APPLET_DEFAULT_ENABLED", "false").lower() == "true"
        applet_adapter = values.get("APPLET_ADAPTER", "none")
        applet_support = values.get("APPLET_SUPPORT", "none")
        applet_caps = [x for x in values.get("APPLET_CAPABILITIES", "").split(";") if x]

        if applet_adapter not in APPLET_ADAPTERS:
            errors.append(f"APPLET_ADAPTER={applet_adapter!r} ist unbekannt.")
        if applet_support not in APPLET_SUPPORT:
            errors.append(f"APPLET_SUPPORT={applet_support!r} ist unbekannt.")
        unknown_caps = sorted(set(applet_caps) - APPLET_CAPABILITIES)
        if unknown_caps:
            errors.append("Unbekannte APPLET_CAPABILITIES: " + ", ".join(unknown_caps))
        if applet_adapter == "none":
            if applet_available or applet_default or applet_caps or applet_support != "none":
                errors.append(
                    "APPLET_ADAPTER=none verlangt AVAILABLE=false, DEFAULT_ENABLED=false, "
                    "SUPPORT=none und keine Capabilities."
                )
        else:
            if not applet_available:
                errors.append("Ein Applet-Adapter verlangt APPLET_AVAILABLE=true.")
            if applet_support == "none":
                errors.append("Ein verfügbares Applet verlangt APPLET_SUPPORT=experimental|supported.")

        owned = sorted(CATEGORY_OWNED.intersection(values))
        if owned:
            errors.append(
                "Diese Felder werden zentral durch die Kategorie gesteuert und dürfen nicht in der App-Datei stehen: "
                + ", ".join(owned)
            )
        if errors:
            print(f"Ungültige App-Definition {conf.name}:", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
            raise SystemExit(1)
        return

    raise SystemExit(f"Unbekannte Aktion: {action}")


if __name__ == "__main__":
    main()
