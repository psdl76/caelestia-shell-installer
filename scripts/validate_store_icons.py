#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shlex
import sys
from pathlib import Path


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
    return values


def valid_icon(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size == 0:
        return False
    head = path.read_bytes()[:16]
    if path.suffix == ".svg":
        try:
            return "<svg" in path.read_text(encoding="utf-8", errors="ignore")[:8192].lower()
        except OSError:
            return False
    if path.suffix == ".png":
        return head.startswith(b"\x89PNG\r\n\x1a\n")
    if path.suffix == ".webp":
        return head.startswith(b"RIFF") and head[8:12] == b"WEBP"
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--cache", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    cache = args.cache or (Path.home() / ".cache/caelestia-webapps/store-icons-v6")
    confs = sorted((root / "apps").glob("*.conf"))

    mappings = 0
    resolved = 0
    missing_mapping: list[str] = []
    missing_icon: list[str] = []

    for conf in confs:
        data = parse_conf(conf)
        app_id = data.get("APP_ID", conf.stem)
        icon_name = data.get("ICON_NAME", app_id)
        if data.get("ICON_PROVIDER") and data.get("ICON_ID"):
            mappings += 1
        else:
            missing_mapping.append(app_id)
        candidates = [cache / f"{icon_name}{ext}" for ext in (".svg", ".png", ".webp")]
        if any(valid_icon(candidate) for candidate in candidates):
            resolved += 1
        else:
            missing_icon.append(app_id)

    result = {
        "apps": len(confs),
        "mappings": mappings,
        "resolved": resolved,
        "missingMappings": missing_mapping,
        "missingIcons": missing_icon,
        "cache": str(cache),
        "pass": len(confs) == 79 and mappings == 79 and resolved == 79,
    }
    if args.json:
        print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    else:
        print(f"apps={result['apps']} mappings={mappings} resolved={resolved}")
        if missing_mapping:
            print("missing mappings: " + ", ".join(missing_mapping))
        if missing_icon:
            print("missing icons: " + ", ".join(missing_icon))
        print("PASS" if result["pass"] else "FAIL")
    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
