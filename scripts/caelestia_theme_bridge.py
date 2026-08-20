#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, os, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_TEMPLATE = ROOT / "data" / "caelestia" / "caelestia-webapps.json"
ROLES = (
    "background","surface","surfaceContainerLowest","surfaceContainerLow",
    "surfaceContainer","surfaceContainerHigh","surfaceContainerHighest",
    "onSurface","onSurfaceVariant","outline","outlineVariant",
    "primary","onPrimary","secondary","secondaryContainer",
    "onSecondaryContainer","tertiary","error","onError",
    "errorContainer","onErrorContainer","scrim",
)

def xdg(name: str, fallback: Path) -> Path:
    value = os.environ.get(name, "").strip()
    return Path(value).expanduser() if value else fallback

HOME = Path.home()
CONFIG_HOME = xdg("XDG_CONFIG_HOME", HOME / ".config")
STATE_HOME = xdg("XDG_STATE_HOME", HOME / ".local/state")
USER_TEMPLATE = CONFIG_HOME / "caelestia/templates" / SOURCE_TEMPLATE.name
SCHEME_JSON = STATE_HOME / "caelestia/scheme.json"
RENDERED_THEME = STATE_HOME / "caelestia/theme" / SOURCE_TEMPLATE.name

def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
    finally:
        try:
            os.unlink(tmp)
        except FileNotFoundError:
            pass

def install_template() -> None:
    desired = SOURCE_TEMPLATE.read_text(encoding="utf-8")
    try:
        current = USER_TEMPLATE.read_text(encoding="utf-8")
    except FileNotFoundError:
        current = None
    if current != desired:
        atomic_write(USER_TEMPLATE, desired)

def normalise_hex(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    value = value.strip().lstrip("#")
    if len(value) not in (6, 8):
        return None
    try:
        int(value, 16)
    except ValueError:
        return None
    return "#" + value.lower()

def hydrate() -> None:
    try:
        scheme = json.loads(SCHEME_JSON.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, json.JSONDecodeError):
        return
    colours = scheme.get("colours")
    if not isinstance(colours, dict):
        return

    rendered: dict[str, object] = {"mode": scheme.get("mode", "dark")}
    for role in ROLES:
        value = normalise_hex(colours.get(role))
        if value is not None:
            rendered[role] = value

    required = ("background","surface","onSurface","primary","onPrimary","error")
    if any(role not in rendered for role in required):
        return

    text = json.dumps(rendered, indent=2, ensure_ascii=False) + "\n"
    try:
        current = RENDERED_THEME.read_text(encoding="utf-8")
    except FileNotFoundError:
        current = None
    if current != text:
        atomic_write(RENDERED_THEME, text)

def status() -> dict[str, object]:
    return {
        "template": str(USER_TEMPLATE),
        "templateInstalled": USER_TEMPLATE.is_file(),
        "scheme": str(SCHEME_JSON),
        "schemeAvailable": SCHEME_JSON.is_file(),
        "renderedTheme": str(RENDERED_THEME),
        "renderedThemeAvailable": RENDERED_THEME.is_file(),
    }

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--status", action="store_true")
    args = parser.parse_args()
    if args.status:
        print(json.dumps(status(), ensure_ascii=False))
        return 0
    install_template()
    hydrate()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
