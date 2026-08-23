#!/usr/bin/env python3
import base64
import contextlib
import fcntl
import json
import os
import time
import re
import shlex
import shutil
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

from category_store import merged_categories, user_category_file

ROOT = Path(__file__).resolve().parent.parent
BUILTIN_DIR = ROOT / "apps"
CATEGORY_FILE = ROOT / "config/categories.json"
ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
ICON_MODES = {"auto", "url", "local"}

LOCK_BUSY_EXIT = 75

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
    timeout = float(os.environ.get("CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS", "2"))
    deadline = time.monotonic() + max(timeout, 0.0)
    with path.open("a+") as handle:
        while True:
            try:
                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    fail("action_busy", "Eine andere WebApps-Aktion läuft bereits.", LOCK_BUSY_EXIT)
                time.sleep(0.05)
        old = os.environ.get("CAELESTIA_WEBAPPS_LOCK_HELD")
        os.environ["CAELESTIA_WEBAPPS_LOCK_HELD"] = "exclusive"
        try:
            yield
        finally:
            if old is None:
                os.environ.pop("CAELESTIA_WEBAPPS_LOCK_HELD", None)
            else:
                os.environ["CAELESTIA_WEBAPPS_LOCK_HELD"] = old
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


def fail(code: str, message: str, exit_code: int = 2) -> None:
    print(json.dumps({"ok": False, "error": {"code": code, "message": message}}, ensure_ascii=False))
    raise SystemExit(exit_code)

def user_dir() -> Path:
    root = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config")))
    return root / "caelestia-webapps" / "apps"

def user_icon_dir() -> Path:
    root = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    return root / "caelestia-webapps" / "user-icons"

def q(value: str) -> str:
    return shlex.quote(value)

def categories() -> set[str]:
    return set(merged_categories(CATEGORY_FILE, user_category_file()))

def dashboard_icon_url(app_id: str) -> str:
    return f"https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/{app_id}.svg"

def local_path(value: str) -> Path:
    parsed = urlparse(value)
    if parsed.scheme == "file":
        if parsed.netloc not in {"", "localhost"}:
            fail("invalid_icon_file", "Lokale Icon-Datei muss auf diesem Rechner liegen.")
        return Path(unquote(parsed.path)).expanduser()
    if parsed.scheme:
        fail("invalid_icon_file", "Lokales Icon muss ein Dateipfad oder file://-Pfad sein.")
    return Path(value).expanduser()

def svg_is_valid(path: Path) -> bool:
    try:
        head = path.read_bytes()[:8192].lower()
    except OSError:
        return False
    return b"<svg" in head

def png_is_valid(path: Path) -> bool:
    try:
        return path.read_bytes()[:8] == b"\x89PNG\r\n\x1a\n"
    except OSError:
        return False

def remove_managed_icon(app_id: str) -> None:
    d = user_icon_dir()
    for suffix in (".svg", ".source.png"):
        try:
            (d / f"{app_id}{suffix}").unlink()
        except FileNotFoundError:
            pass

def import_local_icon(app_id: str, source_value: str) -> str:
    source = local_path(source_value).resolve()
    if not source.is_file():
        fail("icon_file_missing", f"Icon-Datei wurde nicht gefunden: {source}")
    d = user_icon_dir()
    d.mkdir(parents=True, exist_ok=True, mode=0o700)
    target = d / f"{app_id}.svg"
    tmp = d / f".{app_id}.svg.tmp"
    if svg_is_valid(source):
        shutil.copyfile(source, tmp)
    elif png_is_valid(source):
        raw = source.read_bytes()
        source_copy = d / f"{app_id}.source.png"
        source_tmp = d / f".{app_id}.source.png.tmp"
        source_tmp.write_bytes(raw)
        os.chmod(source_tmp, 0o600)
        source_tmp.replace(source_copy)
        encoded = base64.b64encode(raw).decode("ascii")
        tmp.write_text(
            '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">\n'
            f'  <image width="512" height="512" preserveAspectRatio="xMidYMid meet" href="data:image/png;base64,{encoded}"/>\n'
            '</svg>\n', encoding="utf-8")
    else:
        fail("unsupported_icon", "Lokale Icons müssen SVG oder PNG sein.")
    os.chmod(tmp, 0o600)
    tmp.replace(target)
    return str(target)

def validate(payload: dict, editing_id: str | None = None) -> dict:
    app_id = str(payload.get("id", "")).strip().lower()
    name = str(payload.get("name", "")).strip()
    url = str(payload.get("url", "")).strip()
    category = str(payload.get("category", "")).strip()
    icon_mode = str(payload.get("iconMode", "auto")).strip().lower() or "auto"
    icon_url = str(payload.get("iconUrl", "")).strip()
    icon_file = str(payload.get("iconFile", "")).strip()
    generic = str(payload.get("genericName", "Web Application")).strip() or "Web Application"
    comment = str(payload.get("comment", "")).strip() or name
    notification = str(payload.get("notificationMatch", "")).strip() or name
    if not ID_RE.fullmatch(app_id): fail("invalid_id", "App-ID darf nur Kleinbuchstaben, Zahlen und Bindestriche enthalten.")
    if editing_id and app_id != editing_id: fail("id_immutable", "Die App-ID kann nach dem Anlegen nicht geändert werden.")
    if not name: fail("invalid_name", "Name darf nicht leer sein.")
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc: fail("invalid_url", "URL muss eine gültige http://- oder https://-Adresse sein.")
    if category not in categories(): fail("invalid_category", f"Unbekannte Kategorie: {category}")
    if icon_mode not in ICON_MODES: fail("invalid_icon_mode", "Icon-Modus muss auto, url oder local sein.")
    if (BUILTIN_DIR / f"{app_id}.conf").is_file(): fail("builtin_conflict", f"'{app_id}' ist eine eingebaute App und kann nicht überschrieben werden.")
    if icon_mode == "auto":
        icon_url = dashboard_icon_url(app_id); icon_file = ""
    elif icon_mode == "url":
        parsed_icon = urlparse(icon_url)
        if parsed_icon.scheme not in {"http", "https"} or not parsed_icon.netloc: fail("invalid_icon_url", "Icon-URL muss eine gültige http://- oder https://-Adresse sein.")
        icon_file = ""
    else:
        if not icon_file: fail("missing_icon_file", "Bitte eine lokale SVG- oder PNG-Datei auswählen.")
        icon_url = ""
    return {"id":app_id,"name":name,"url":url,"category":category,"iconMode":icon_mode,"iconUrl":icon_url,"iconFile":icon_file,"genericName":generic,"comment":comment,"notificationMatch":notification}

def prepare_icon(app: dict, previous_local: str = "") -> dict:
    app = dict(app); app_id=app["id"]; mode=app["iconMode"]
    if mode == "local":
        requested=app.get("iconFile",""); managed=str(user_icon_dir()/f"{app_id}.svg")
        if requested and local_path(requested).expanduser().resolve() != Path(managed).expanduser().resolve():
            app["iconFile"] = import_local_icon(app_id, requested)
        elif Path(managed).is_file(): app["iconFile"] = managed
        elif previous_local and Path(previous_local).is_file(): app["iconFile"] = previous_local
        else: fail("icon_file_missing", "Das gespeicherte lokale Icon fehlt; bitte erneut auswählen.")
    else:
        remove_managed_icon(app_id); app["iconFile"]=""
    return app

def render(app: dict) -> str:
    app_id=app["id"]; keywords=f'{app["name"]};WebApp;'
    rows=["# Caelestia WebApps user definition",'APP_SOURCE="user"',f"APP_ID={q(app_id)}",f"APP_NAME={q(app['name'])}",f"APP_GENERIC_NAME={q(app['genericName'])}",f"APP_COMMENT={q(app['comment'])}",f"APP_URL={q(app['url'])}",'APP_CATEGORIES="Network;"',f"APP_KEYWORDS={q(keywords)}",f"APP_CATALOG_CATEGORY={q(app['category'])}",f"MOZ_APP_REMOTINGNAME={q(app_id)}",f"WINDOW_CLASS={q(app_id)}",f"ICON_NAME={q(app_id)}",f"APP_ICON_MODE={q(app['iconMode'])}"]
    if app["iconMode"] == "local": rows += [f"ICON_LOCAL_FILE={q(app['iconFile'])}",'ICON_URL=""']
    else: rows += [f"ICON_URL={q(app['iconUrl'])}",'ICON_LOCAL_FILE=""']
    rows += ['USE_OPAQUE_TAG="true"',f"NOTIFICATION_MATCH={q(app['notificationMatch'])}",""]
    return "\n".join(rows)

def parse_existing(path: Path) -> dict[str,str]:
    result={}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line=raw.strip()
        if not line or line.startswith("#") or "=" not in line: continue
        key,value=line.split("=",1)
        try:
            parts=shlex.split(value,posix=True); result[key]=parts[0] if parts else ""
        except ValueError: result[key]=value.strip('"\'')
    return result

def write_definition(path: Path, app: dict) -> None:
    path.parent.mkdir(parents=True,exist_ok=True,mode=0o700)
    tmp=path.with_suffix(".conf.tmp"); tmp.write_text(render(app),encoding="utf-8"); os.chmod(tmp,0o600); tmp.replace(path)

def create(payload: dict) -> dict:
    app=validate(payload); path=user_dir()/f"{app['id']}.conf"
    if path.exists(): fail("already_exists",f"User-App '{app['id']}' existiert bereits.",4)
    app=prepare_icon(app); write_definition(path,app); return app

def update(app_id: str, payload: dict) -> dict:
    path=user_dir()/f"{app_id}.conf"
    if not path.is_file(): fail("not_user_app",f"User-App '{app_id}' existiert nicht.",3)
    existing=parse_existing(path); app=validate(payload,editing_id=app_id); app=prepare_icon(app,existing.get("ICON_LOCAL_FILE","")); write_definition(path,app); return app

def delete_definition(app_id: str) -> None:
    path=user_dir()/f"{app_id}.conf"
    if not path.is_file(): fail("not_user_app",f"User-App '{app_id}' existiert nicht.",3)
    path.unlink(); remove_managed_icon(app_id)

def main() -> None:
    if len(sys.argv)<2: fail("usage","usage: user_apps.py create|update|delete ...")
    cmd=sys.argv[1]
    try:
        if cmd=="create" and len(sys.argv)==3:
            with mutation_lock():
                payload=json.loads(sys.argv[2]); print(json.dumps({"ok":True,"app":create(payload)},ensure_ascii=False)); return
        if cmd=="update" and len(sys.argv)==4:
            with mutation_lock():
                payload=json.loads(sys.argv[3]); print(json.dumps({"ok":True,"app":update(sys.argv[2],payload)},ensure_ascii=False)); return
        if cmd=="delete" and len(sys.argv)==3:
            with mutation_lock():
                delete_definition(sys.argv[2]); print(json.dumps({"ok":True,"id":sys.argv[2]},ensure_ascii=False)); return
    except json.JSONDecodeError: fail("invalid_json","Ungültige JSON-Nutzdaten.")
    fail("usage","usage: user_apps.py create JSON | update ID JSON | delete ID")

if __name__ == "__main__": main()
