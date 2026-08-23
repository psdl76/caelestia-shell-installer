#!/usr/bin/env python3
"""Shared loader and validation for built-in and user-owned categories."""

from __future__ import annotations

import json
import os
import re
import unicodedata
from pathlib import Path
from typing import Any


SCHEMA_VERSION = 1
RESERVED_IDS = {"featured", "all", "installed"}
CATEGORY_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
ICON_KEYS = {
    "category",
    "devices",
    "energy",
    "health",
    "home",
    "lightbulb",
    "media",
    "school",
    "security",
    "shopping",
    "thermostat",
    "work",
}


class CategoryError(ValueError):
    def __init__(self, code: str, message: str):
        super().__init__(message)
        self.code = code


def user_category_file() -> Path:
    config_root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    return config_root / "caelestia-webapps" / "categories.json"


def load_builtin_categories(path: Path) -> dict[str, dict[str, Any]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CategoryError("invalid_builtin_categories", f"Ungültiges Kategorie-Schema: {path}") from exc
    categories = payload.get("categories")
    if payload.get("schemaVersion") != SCHEMA_VERSION or not isinstance(categories, dict):
        raise CategoryError("invalid_builtin_categories", f"Ungültiges Kategorie-Schema: {path}")
    return categories


def _validate_user_record(category_id: str, value: object) -> dict[str, str]:
    if not CATEGORY_ID_RE.fullmatch(category_id) or category_id in RESERVED_IDS:
        raise CategoryError("invalid_category_id", f"Ungültige Benutzerkategorie-ID: {category_id}")
    if not isinstance(value, dict):
        raise CategoryError("invalid_user_categories", f"Ungültiger Eintrag für Benutzerkategorie: {category_id}")
    label = str(value.get("label", "")).strip()
    icon = str(value.get("icon", "")).strip()
    if not label or len(label) > 64 or any(ord(char) < 32 for char in label):
        raise CategoryError("invalid_category_name", f"Ungültiger Kategoriename: {category_id}")
    if icon not in ICON_KEYS:
        raise CategoryError("invalid_category_icon", f"Ungültiges Kategorie-Icon: {icon}")
    return {"label": label, "icon": icon}


def load_user_categories(path: Path | None = None) -> dict[str, dict[str, str]]:
    target = path or user_category_file()
    if not target.exists():
        return {}
    try:
        payload = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CategoryError("invalid_user_categories", f"Ungültige Benutzerkategorien: {target}") from exc
    categories = payload.get("categories")
    if payload.get("schemaVersion") != SCHEMA_VERSION or not isinstance(categories, dict):
        raise CategoryError("invalid_user_categories", f"Ungültige Benutzerkategorien: {target}")
    return {category_id: _validate_user_record(category_id, value) for category_id, value in categories.items()}


def neutral_runtime_category(category_id: str, value: dict[str, str], order: int) -> dict[str, Any]:
    return {
        "appletVisible": False,
        "appletShowBadge": False,
        "appletNotificationPreview": False,
        "hyprSharedTag": "",
        "hyprSharedOwner": "",
        "hyprSharedWorkspace": "",
        "hyprSharedLocalDecl": "",
        "hyprSharedRuleMarker": "",
        "hyprSharedCreateTag": "",
        "hyprSharedKeybind": "",
        "label": value["label"],
        "icon": value["icon"],
        "order": order,
        "source": "user",
        "id": category_id,
    }


def merged_categories(builtin_path: Path, user_path: Path | None = None) -> dict[str, dict[str, Any]]:
    builtins = load_builtin_categories(builtin_path)
    users = load_user_categories(user_path)
    collisions = sorted(set(builtins) & set(users))
    if collisions:
        raise CategoryError("category_conflict", "Benutzerkategorie kollidiert mit eingebauter Kategorie: " + ", ".join(collisions))
    merged = {category_id: dict(value) for category_id, value in builtins.items()}
    ordered_users = sorted(users.items(), key=lambda item: (item[1]["label"].casefold(), item[0]))
    for offset, (category_id, value) in enumerate(ordered_users):
        merged[category_id] = neutral_runtime_category(category_id, value, 1000 + offset)
    return merged


def slugify_label(label: str) -> str:
    prepared = label.strip().casefold().replace("ß", "ss")
    normalized = unicodedata.normalize("NFKD", prepared)
    ascii_label = normalized.encode("ascii", "ignore").decode("ascii")
    return re.sub(r"^-+|-+$", "", re.sub(r"[^a-z0-9]+", "-", ascii_label))


def validate_category_payload(payload: object) -> dict[str, str]:
    if not isinstance(payload, dict):
        raise CategoryError("invalid_payload", "Kategorie-Daten müssen ein JSON-Objekt sein.")
    label = str(payload.get("label", "")).strip()
    icon = str(payload.get("icon", "")).strip()
    if not label or len(label) > 64 or any(ord(char) < 32 for char in label):
        raise CategoryError("invalid_category_name", "Der Kategoriename muss 1 bis 64 gültige Zeichen enthalten.")
    if icon not in ICON_KEYS:
        raise CategoryError("invalid_category_icon", "Bitte ein angebotenes Kategorie-Icon auswählen.")
    return {"label": label, "icon": icon}


def write_user_categories(path: Path, categories: dict[str, dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(path.parent, 0o700)
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    payload = {"schemaVersion": SCHEMA_VERSION, "categories": categories}
    try:
        with tmp.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    finally:
        try:
            tmp.unlink()
        except FileNotFoundError:
            pass
