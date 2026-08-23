#!/usr/bin/env python3
from __future__ import annotations

import json
import contextlib
import fcntl
import os
import re
import shlex
import sys
import time
from pathlib import Path

from category_store import (
    CategoryError,
    RESERVED_IDS,
    load_builtin_categories,
    load_user_categories,
    slugify_label,
    user_category_file,
    validate_category_payload,
    write_user_categories,
)


ROOT = Path(__file__).resolve().parent.parent
BUILTIN_CATEGORY_FILE = ROOT / "config" / "categories.json"
BUILTIN_APP_DIR = ROOT / "apps"
LOCK_BUSY_EXIT = 75


def fail(code: str, message: str, exit_code: int = 2) -> None:
    print(json.dumps({"ok": False, "error": {"code": code, "message": message}}, ensure_ascii=False))
    raise SystemExit(exit_code)


def lock_path() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR", "").strip()
    if runtime:
        return Path(runtime) / "caelestia-webapps" / "mutation.lock"
    return Path.home() / ".local/state/caelestia-webapps/locks/mutation.lock"


@contextlib.contextmanager
def mutation_lock():
    if os.environ.get("CAELESTIA_WEBAPPS_LOCK_HELD") == "exclusive":
        yield
        return
    path = lock_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    timeout = max(float(os.environ.get("CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS", "2")), 0.0)
    deadline = time.monotonic() + timeout
    with path.open("a+") as handle:
        while True:
            try:
                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    fail("action_busy", "Eine andere WebApps-Aktion läuft bereits.", LOCK_BUSY_EXIT)
                time.sleep(0.05)
        try:
            yield
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def parse_conf(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError:
        return values
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, raw_value = line.split("=", 1)
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key):
            continue
        try:
            parts = shlex.split(raw_value, posix=True)
        except ValueError:
            continue
        if len(parts) == 1:
            values[key] = parts[0]
    return values


def user_app_dir() -> Path:
    root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    return root / "caelestia-webapps" / "apps"


def data_root() -> Path:
    return Path.home() / ".local/share/caelestia-webapps"


def category_references(category_id: str) -> list[str]:
    references: list[str] = []
    for directory in (BUILTIN_APP_DIR, user_app_dir()):
        if not directory.is_dir():
            continue
        for conf in sorted(directory.glob("*.conf")):
            values = parse_conf(conf)
            categories = [values.get("APP_CATALOG_CATEGORY", "")]
            categories.extend(item for item in values.get("APP_CATALOG_CATEGORIES_LIST", "").split(";") if item)
            if category_id in categories:
                references.append(f"definition:{values.get('APP_ID', conf.stem)}")
    apps_root = data_root() / "apps"
    if apps_root.is_dir():
        for metadata in sorted(apps_root.glob("*/installed.conf")):
            values = parse_conf(metadata)
            if values.get("APP_CATALOG_CATEGORY") == category_id:
                references.append(f"installation:{values.get('APP_ID', metadata.parent.name)}")
    return sorted(set(references))


def create(payload: object) -> dict[str, str]:
    value = validate_category_payload(payload)
    category_id = slugify_label(value["label"])
    if not category_id or category_id in RESERVED_IDS:
        raise CategoryError("invalid_category_id", "Aus diesem Namen kann keine gültige Kategorie-ID erzeugt werden.")
    builtins = load_builtin_categories(BUILTIN_CATEGORY_FILE)
    users = load_user_categories()
    if category_id in builtins or category_id in users:
        raise CategoryError("category_exists", f"Kategorie '{category_id}' existiert bereits.")
    users[category_id] = value
    write_user_categories(user_category_file(), users)
    return {"id": category_id, **value, "source": "user", "count": 0, "deletable": True}


def update(category_id: str, payload: object) -> dict[str, str]:
    value = validate_category_payload(payload)
    users = load_user_categories()
    if category_id not in users:
        raise CategoryError("not_user_category", f"Benutzerkategorie '{category_id}' existiert nicht.")
    users[category_id] = value
    write_user_categories(user_category_file(), users)
    return {"id": category_id, **value, "source": "user"}


def delete(category_id: str) -> dict[str, str]:
    users = load_user_categories()
    if category_id not in users:
        raise CategoryError("not_user_category", f"Benutzerkategorie '{category_id}' existiert nicht.")
    references = category_references(category_id)
    if references:
        raise CategoryError("category_in_use", "Die Kategorie wird noch verwendet und kann nicht gelöscht werden.")
    del users[category_id]
    write_user_categories(user_category_file(), users)
    return {"id": category_id}


def main() -> None:
    try:
        with mutation_lock():
            if len(sys.argv) == 3 and sys.argv[1] == "create":
                result = create(json.loads(sys.argv[2]))
            elif len(sys.argv) == 4 and sys.argv[1] == "update":
                result = update(sys.argv[2], json.loads(sys.argv[3]))
            elif len(sys.argv) == 3 and sys.argv[1] == "delete":
                result = delete(sys.argv[2])
            else:
                fail("usage", "usage: user_categories.py create JSON | update ID JSON | delete ID")
        print(json.dumps({"ok": True, "category": result}, ensure_ascii=False))
    except json.JSONDecodeError:
        fail("invalid_json", "Kategorie-Daten enthalten kein gültiges JSON.")
    except CategoryError as exc:
        fail(exc.code, str(exc))


if __name__ == "__main__":
    main()
