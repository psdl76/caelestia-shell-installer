#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shlex
import sys
from pathlib import Path
from urllib.parse import urlparse

APPLET_ADAPTERS = {"none", "notifications", "media", "mail", "calendar"}
APPLET_SUPPORT = {"none", "experimental", "supported"}
ADAPTER_CAPABILITIES = {
    "none": set(),
    "notifications": {"notifications", "badge", "preview"},
    "media": {"now_playing", "playback_controls", "artwork", "live_preview", "video_crop", "pin"},
    "mail": {"unread", "latest_mail"},
    "calendar": {"next_event", "upcoming_events"},
}
ICON_PROVIDERS = {"dashboard-icons", "dashboard-icons-external-lobehub", "canva-official"}
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
HOST_RE = re.compile(r"^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)*[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$", re.I)
REQUIRED = {
    "APP_ID", "APP_NAME", "APP_GENERIC_NAME", "APP_COMMENT", "APP_URL",
    "APP_CATALOG_CATEGORY", "MOZ_APP_REMOTINGNAME",
    "WINDOW_CLASS", "ICON_NAME", "ICON_PROVIDER", "ICON_ID", "APP_PROVIDER",
    "APP_FEATURED", "APPLET_AVAILABLE", "APPLET_DEFAULT_ENABLED", "APPLET_ADAPTER",
    "APPLET_SUPPORT", "APPLET_CAPABILITIES", "APPLET_MATCH_HOSTS",
}
CATEGORY_OWNED = {
    "APPLET_VISIBLE", "APPLET_SHOW_BADGE", "APPLET_NOTIFICATION_PREVIEW",
    "HYPR_SHARED_TAG", "HYPR_SHARED_OWNER", "HYPR_SHARED_WORKSPACE",
    "HYPR_SHARED_LOCAL_DECL", "HYPR_SHARED_RULE_MARKER", "HYPR_SHARED_CREATE_TAG",
    "HYPR_SHARED_KEYBIND",
}


def add_violation(violations: list[dict[str, object]], errors: list[str], *, code: str, app: str | None = None, field: str | None = None, message: str, expected: object | None = None, actual: object | None = None) -> None:
    item: dict[str, object] = {"code": code, "message": message}
    if app is not None: item["app"] = app
    if field is not None: item["field"] = field
    if expected is not None: item["expected"] = expected
    if actual is not None: item["actual"] = actual
    violations.append(item)
    prefix = f"{app}: " if app else ""
    field_text = f"{field}: " if field else ""
    errors.append(f"{prefix}{field_text}{message}")



def parse_conf(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key):
            continue
        try:
            parts = shlex.split(value, posix=True)
        except ValueError as exc:
            raise ValueError(f"{path.name}:{line_no}: invalid shell value: {exc}") from exc
        if len(parts) == 1:
            out[key] = parts[0]
        elif value == '""' or value == "''" or value == "":
            out[key] = ""
    return out


def slist(value: str) -> list[str]:
    return [x.strip() for x in value.split(";") if x.strip()]


def as_bool(value: str, field: str, errors: list[str]) -> bool:
    if value not in {"true", "false"}:
        errors.append(f"{field}: expected true|false, got {value!r}")
    return value == "true"


def valid_http_url(value: str) -> bool:
    p = urlparse(value)
    return p.scheme in {"http", "https"} and bool(p.netloc)


def validate(root: Path) -> tuple[dict[str, object], list[str], list[dict[str, object]]]:
    errors: list[str] = []
    violations: list[dict[str, object]] = []
    category_path = root / "config/categories.json"
    try:
        category_data = json.loads(category_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return {}, [f"categories.json: {exc}"], [{"code":"categories_parse","field":"config/categories.json","message":str(exc)}]
    categories = category_data.get("categories")
    if category_data.get("schemaVersion") != 1 or not isinstance(categories, dict):
        return {}, ["categories.json: expected schemaVersion=1 and categories object"], [{"code":"categories_schema","field":"config/categories.json","message":"expected schemaVersion=1 and categories object"}]
    category_ids = set(categories)

    files = sorted((root / "apps").glob("*.conf"))
    seen: set[str] = set()
    stats = {"apps": 0, "featured": 0, "appletCapable": 0, "supported": 0, "experimental": 0, "defaultEnabled": 0, "categories": len(category_ids)}

    for path in files:
        try:
            v = parse_conf(path)
        except ValueError as exc:
            errors.append(str(exc)); continue
        prefix = path.name
        missing = sorted(REQUIRED - set(v))
        if missing:
            add_violation(violations, errors, code="missing_fields", app=path.stem, field="definition", message=f"missing fields: {', '.join(missing)}", expected="all required fields", actual=missing)
            continue
        app_id = v["APP_ID"]
        stats["apps"] += 1
        if not ID_RE.fullmatch(app_id): errors.append(f"{prefix}: invalid APP_ID={app_id!r}")
        if app_id != path.stem: errors.append(f"{prefix}: APP_ID must match filename stem ({path.stem!r})")
        if app_id in seen: errors.append(f"{prefix}: duplicate APP_ID={app_id!r}")
        seen.add(app_id)
        if not valid_http_url(v["APP_URL"]): errors.append(f"{prefix}: APP_URL must be a complete http(s) URL")
        if not v["APP_COMMENT"].strip(): errors.append(f"{prefix}: APP_COMMENT must not be empty")

        primary = v["APP_CATALOG_CATEGORY"]
        cats = slist(v.get("APP_CATALOG_CATEGORIES_LIST", "")) or [primary]
        if primary not in category_ids: errors.append(f"{prefix}: unknown primary category {primary!r}")
        unknown_cats = sorted(set(cats) - category_ids)
        if unknown_cats: errors.append(f"{prefix}: unknown categories {unknown_cats}")
        if primary not in cats: add_violation(violations, errors, code="primary_category_missing", app=app_id, field="APP_CATALOG_CATEGORIES_LIST", message=f"must include primary category {primary!r}", expected=primary, actual=cats)
        if len(cats) != len(set(cats)): errors.append(f"{prefix}: duplicate category in APP_CATALOG_CATEGORIES_LIST")

        owned = sorted(CATEGORY_OWNED.intersection(v))
        if owned: errors.append(f"{prefix}: category-owned fields are forbidden: {', '.join(owned)}")

        featured = as_bool(v["APP_FEATURED"], f"{prefix}: APP_FEATURED", errors)
        if featured: stats["featured"] += 1
        available = as_bool(v["APPLET_AVAILABLE"], f"{prefix}: APPLET_AVAILABLE", errors)
        default = as_bool(v["APPLET_DEFAULT_ENABLED"], f"{prefix}: APPLET_DEFAULT_ENABLED", errors)
        if default: stats["defaultEnabled"] += 1
        adapter = v["APPLET_ADAPTER"]
        support = v["APPLET_SUPPORT"]
        caps = slist(v["APPLET_CAPABILITIES"])
        hosts = slist(v["APPLET_MATCH_HOSTS"])
        if adapter not in APPLET_ADAPTERS: errors.append(f"{prefix}: unsupported APPLET_ADAPTER={adapter!r}")
        if support not in APPLET_SUPPORT: errors.append(f"{prefix}: unsupported APPLET_SUPPORT={support!r}")
        if adapter in ADAPTER_CAPABILITIES:
            invalid_caps = sorted(set(caps) - ADAPTER_CAPABILITIES[adapter])
            if invalid_caps: add_violation(violations, errors, code="adapter_capability_mismatch", app=app_id, field="APPLET_CAPABILITIES", message=f"capabilities {invalid_caps} do not belong to adapter {adapter!r}", expected=sorted(ADAPTER_CAPABILITIES[adapter]), actual=caps)
        if len(caps) != len(set(caps)): errors.append(f"{prefix}: duplicate APPLET_CAPABILITIES")
        if any(not HOST_RE.fullmatch(h) for h in hosts): errors.append(f"{prefix}: invalid APPLET_MATCH_HOSTS")
        if len(hosts) != len(set(hosts)): errors.append(f"{prefix}: duplicate APPLET_MATCH_HOSTS")
        if adapter == "none":
            if available or default or support != "none" or caps or hosts:
                errors.append(f"{prefix}: adapter=none requires available=false, default=false, support=none, no capabilities/hosts")
        else:
            stats["appletCapable"] += 1
            if not available: errors.append(f"{prefix}: non-none adapter requires APPLET_AVAILABLE=true")
            if support not in {"experimental", "supported"}: errors.append(f"{prefix}: applet requires support=experimental|supported")
            if default: add_violation(violations, errors, code="applet_default_enabled", app=app_id, field="APPLET_DEFAULT_ENABLED", message="core catalog applets must default to disabled", expected="false", actual=v["APPLET_DEFAULT_ENABLED"])
            if not caps: errors.append(f"{prefix}: available applet requires at least one capability")
            if support == "supported": stats["supported"] += 1
            if support == "experimental": stats["experimental"] += 1
            if adapter == "media" and not hosts: errors.append(f"{prefix}: media adapter requires APPLET_MATCH_HOSTS")
            if adapter != "media" and hosts: errors.append(f"{prefix}: only media adapter may currently declare APPLET_MATCH_HOSTS")

        provider = v["ICON_PROVIDER"]
        icon_id = v["ICON_ID"].strip()
        if provider not in ICON_PROVIDERS: add_violation(violations, errors, code="icon_provider_unsupported", app=app_id, field="ICON_PROVIDER", message=f"unsupported provider {provider!r}", expected=sorted(ICON_PROVIDERS), actual=provider)
        if not icon_id: errors.append(f"{prefix}: ICON_ID must not be empty")
        if provider != "dashboard-icons" and not valid_http_url(v.get("ICON_URL", "")):
            errors.append(f"{prefix}: curated icon provider requires explicit http(s) ICON_URL")

    # Frozen Phase 16.1 core-catalog invariants. These make accidental drift visible.
    expected = {"apps": 79, "categories": 14, "featured": 23, "appletCapable": 21, "supported": 4, "experimental": 17, "defaultEnabled": 0}
    for key, wanted in expected.items():
        if stats.get(key) != wanted:
            add_violation(violations, errors, code="catalog_invariant", field=key, message=f"catalog invariant expected {wanted}, got {stats.get(key)}", expected=wanted, actual=stats.get(key))
    return stats, errors, violations


def main() -> int:
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    stats, errors, violations = validate(root)
    payload = {"ok": not errors, "schemaContract": "phase16.2-v3", "stats": stats, "errors": errors, "violations": violations}
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0 if not errors else 1

if __name__ == "__main__":
    raise SystemExit(main())
