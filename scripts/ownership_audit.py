#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUILTIN = ROOT / "apps"
USER = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "caelestia-webapps/apps"

def ids(path: Path) -> set[str]:
    if not path.is_dir():
        return set()
    return {p.stem for p in path.glob("*.conf") if p.is_file()}

builtins = ids(BUILTIN)
users = ids(USER)
overlap = sorted(builtins & users)

payload = {
    "ok": not overlap,
    "builtInCount": len(builtins),
    "userCount": len(users),
    "shadowedIds": overlap,
    "builtInRoot": str(BUILTIN),
    "userRoot": str(USER),
}
print(json.dumps(payload, indent=2, ensure_ascii=False))
raise SystemExit(0 if not overlap else 2)
