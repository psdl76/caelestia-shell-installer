#!/usr/bin/env python3
"""Phase 16.7 runtime-state migration for Caelestia WebApps.

Normalises the Phase 16.5/16.6 user state files without changing the frozen
catalog or applet-registry schemas. Existing valid user choices are preserved.
Malformed/legacy files are backed up by content hash before an atomic rewrite.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
CHECK_NEEDS_MIGRATION = 10


def parse_bool(value: Any) -> bool | None:
    if isinstance(value, bool):
        return value
    if isinstance(value, int) and value in (0, 1):
        return bool(value)
    if isinstance(value, str):
        raw = value.strip().lower()
        if raw in {"true", "on", "yes", "1", "enabled"}:
            return True
        if raw in {"false", "off", "no", "0", "disabled"}:
            return False
    return None


def read_json(path: Path) -> tuple[Any, bytes | None, str | None]:
    try:
        raw = path.read_bytes()
    except FileNotFoundError:
        return None, None, None
    except OSError as exc:
        return None, None, f"read_error:{exc}"
    try:
        return json.loads(raw.decode("utf-8")), raw, None
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        return None, raw, f"invalid_json:{exc}"


def canonical_applets(data: Any) -> tuple[dict[str, Any], list[str]]:
    notes: list[str] = []
    enabled_src: Any = {}
    if isinstance(data, dict):
        if isinstance(data.get("enabled"), dict):
            enabled_src = data["enabled"]
        else:
            # Tolerate a pre-schema flat map: {"youtube": true, ...}.
            candidates = {k: v for k, v in data.items() if k not in {"schemaVersion", "enabled"}}
            if candidates:
                enabled_src = candidates
                notes.append("legacy_flat_activation_map")
            elif "enabled" in data:
                notes.append("invalid_enabled_container")
    elif data is not None:
        notes.append("invalid_root")

    enabled: dict[str, bool] = {}
    if isinstance(enabled_src, dict):
        for app_id, value in enabled_src.items():
            parsed = parse_bool(value)
            if parsed is None:
                notes.append(f"dropped_invalid_activation:{app_id}")
                continue
            enabled[str(app_id)] = parsed
    return {"schemaVersion": SCHEMA_VERSION, "enabled": dict(sorted(enabled.items()))}, notes


def canonical_settings(data: Any) -> tuple[dict[str, Any], list[str]]:
    notes: list[str] = []
    apps_src: Any = {}
    if isinstance(data, dict):
        if isinstance(data.get("apps"), dict):
            apps_src = data["apps"]
        else:
            # Tolerate a pre-schema flat app map: {"youtube": {"pin": false}}.
            candidates = {k: v for k, v in data.items() if k not in {"schemaVersion", "apps"}}
            if candidates:
                apps_src = candidates
                notes.append("legacy_flat_settings_map")
            elif "apps" in data:
                notes.append("invalid_apps_container")
    elif data is not None:
        notes.append("invalid_root")

    apps: dict[str, dict[str, bool]] = {}
    if isinstance(apps_src, dict):
        for app_id, values in apps_src.items():
            if not isinstance(values, dict):
                notes.append(f"dropped_invalid_app_settings:{app_id}")
                continue
            clean: dict[str, bool] = {}
            for capability, value in values.items():
                parsed = parse_bool(value)
                if parsed is None:
                    notes.append(f"dropped_invalid_setting:{app_id}:{capability}")
                    continue
                clean[str(capability)] = parsed
            if clean:
                apps[str(app_id)] = dict(sorted(clean.items()))
    return {"schemaVersion": SCHEMA_VERSION, "apps": dict(sorted(apps.items()))}, notes


def encoded(data: dict[str, Any]) -> bytes:
    return (json.dumps(data, ensure_ascii=False, indent=2, sort_keys=False) + "\n").encode("utf-8")


def backup_original(path: Path, raw: bytes, backup_root: Path) -> Path:
    digest = hashlib.sha256(raw).hexdigest()[:16]
    backup_root.mkdir(parents=True, exist_ok=True)
    target = backup_root / f"{path.name}.{digest}.bak"
    if not target.exists():
        target.write_bytes(raw)
        try:
            shutil.copystat(path, target)
        except OSError:
            pass
    return target


def atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(tmp_name, 0o600)
        os.replace(tmp_name, path)
    finally:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass


def process(path: Path, kind: str, backup_root: Path, write: bool) -> dict[str, Any]:
    data, raw, read_error = read_json(path)
    exists = raw is not None or path.exists()
    if not exists:
        return {"file": str(path), "kind": kind, "exists": False, "changed": False, "notes": []}

    if kind == "activation":
        canonical, notes = canonical_applets(data)
    else:
        canonical, notes = canonical_settings(data)
    if read_error:
        notes.insert(0, read_error)

    payload = encoded(canonical)
    changed = raw != payload
    backup = None
    if changed and write:
        if raw is not None:
            backup = backup_original(path, raw, backup_root)
        atomic_write(path, payload)

    return {
        "file": str(path),
        "kind": kind,
        "exists": True,
        "changed": changed,
        "backup": str(backup) if backup else None,
        "notes": notes,
        "entries": len(canonical.get("enabled", canonical.get("apps", {}))),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--state-root", required=True, type=Path)
    parser.add_argument("--check", action="store_true", help="Do not write; return 10 when migration is needed")
    parser.add_argument("--json", action="store_true", help="Emit JSON report")
    args = parser.parse_args()

    state_root: Path = args.state_root
    backup_root = state_root / "migration-backups"
    results = [
        process(state_root / "applets.json", "activation", backup_root, write=not args.check),
        process(state_root / "applet-settings.json", "settings", backup_root, write=not args.check),
    ]
    changed = any(item["changed"] for item in results)
    report = {"schemaVersion": 1, "changed": changed, "checkOnly": args.check, "files": results}
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        for item in results:
            if not item["exists"]:
                print(f"SKIP {item['kind']}: nicht vorhanden")
            elif item["changed"]:
                verb = "NEEDS-MIGRATION" if args.check else "MIGRATED"
                print(f"{verb} {item['kind']}: {item['file']}")
            else:
                print(f"OK {item['kind']}: {item['file']}")
    return CHECK_NEEDS_MIGRATION if args.check and changed else 0


if __name__ == "__main__":
    raise SystemExit(main())
