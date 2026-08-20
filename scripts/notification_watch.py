#!/usr/bin/env python3
from __future__ import annotations

import ast
import fcntl
import json
import os
import re
import shutil
import signal
import struct
import subprocess
import sys
import time
import zlib
from pathlib import Path
from typing import Any

MAX_EVENTS_PER_APP = 20
EVENT_TTL_SECONDS = 6 * 60 * 60


def state_path() -> Path:
    base = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    return base / "caelestia-webapps" / "notification-events.json"


def runtime_root() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR", "").strip()
    return Path(runtime) if runtime else Path.home() / ".local/state"


def lock_path() -> Path:
    return runtime_root() / "caelestia-webapps" / "notification-watch.lock"


def pid_path() -> Path:
    return runtime_root() / "caelestia-webapps" / "notification-watch.pid"


def image_cache_dir() -> Path:
    base = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    return base / "caelestia-webapps" / "notification-images"


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)


def write_raw_notification_png(path: Path, image: dict[str, Any]) -> bool:
    """Write freedesktop image-data to PNG using only the Python stdlib."""
    try:
        width = int(image.get("width", 0))
        height = int(image.get("height", 0))
        rowstride = int(image.get("rowstride", 0))
        has_alpha = bool(image.get("hasAlpha", False))
        bits = int(image.get("bitsPerSample", 0))
        channels = int(image.get("channels", 0))
        raw = bytes(image.get("data", []))
    except (TypeError, ValueError):
        return False
    if width <= 0 or height <= 0 or bits != 8 or channels not in (3, 4):
        return False
    if rowstride < width * channels or len(raw) < rowstride * height:
        return False

    colour_type = 6 if channels == 4 and has_alpha else 2
    rows = bytearray()
    wanted = width * channels
    for y in range(height):
        start = y * rowstride
        row = raw[start:start + wanted]
        if channels == 4 and not has_alpha:
            rgb = bytearray()
            for x in range(0, len(row), 4):
                rgb.extend(row[x:x + 3])
            row = bytes(rgb)
            colour_type = 2
        rows.append(0)  # PNG filter: None
        rows.extend(row)

    png = b"\x89PNG\r\n\x1a\n"
    png += _png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, colour_type, 0, 0, 0))
    png += _png_chunk(b"IDAT", zlib.compress(bytes(rows), 6))
    png += _png_chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_bytes(png)
    os.replace(tmp, path)
    return True


def remove_cached_image(value: str) -> None:
    if not value:
        return
    try:
        path = Path(value)
        if path.parent == image_cache_dir():
            path.unlink(missing_ok=True)
    except OSError:
        pass


def atomic_write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def load_eligible_app_ids(root: Path) -> set[str]:
    proc = subprocess.run(
        [str(root / "bin/caelestia-webapps"), "applet-registry"],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        timeout=20,
    )
    if proc.returncode != 0:
        raise RuntimeError(f"Katalog konnte nicht gelesen werden: {proc.stderr.strip()}")
    payload = json.loads(proc.stdout)
    result: set[str] = set()
    for app in payload.get("data", {}).get("apps", []):
        if not isinstance(app, dict):
            continue
        app_id = str(app.get("id", "")).strip().lower()
        if app_id and app.get("adapter") == "notifications":
            result.add(app_id)
    return result


def parse_quoted(token: str) -> str:
    token = token.strip()
    try:
        value = ast.literal_eval(token)
    except (ValueError, SyntaxError):
        if token.startswith('"') and token.endswith('"'):
            return token[1:-1]
        return token
    return str(value)


def normalize_desktop_entry(value: str) -> str:
    value = value.strip()
    if value.endswith(".desktop"):
        value = value[:-8]
    return value.lower()


def header_value(header: str, name: str) -> str:
    match = re.search(rf"(?:^|\s){re.escape(name)}=([^\s]+)", header)
    return match.group(1) if match else ""


class BusParser:
    """Parse only freedesktop notification calls/replies/signals from dbus-monitor.

    Notify method calls are recorded immediately so UI latency stays low. The
    subsequent method return supplies the daemon-assigned notification id. That
    id lets NotificationClosed remove the exact event later. `replaces_id`
    updates replace the previous event rather than inflating the badge.
    """

    def __init__(self) -> None:
        self.mode = ""
        self.header = ""
        self.depth = 0
        self.top_arrays_completed = 0
        self.top_strings: list[str] = []
        self.desktop_entry = ""
        self.expect_desktop_entry_value = False
        self.replaces_id = 0
        self.image_data: dict[str, Any] | None = None
        self.image_capture = False
        self.image_meta: list[int | bool] = []
        self.image_bytes: list[int] = []
        self.image_bytes_active = False
        self.return_uint: int | None = None
        self.closed_values: list[int] = []

    def _start_notify(self, header: str) -> None:
        self.mode = "notify"
        self.header = header
        self.depth = 0
        self.top_arrays_completed = 0
        self.top_strings = []
        self.desktop_entry = ""
        self.expect_desktop_entry_value = False
        self.replaces_id = 0
        self.image_data = None
        self.image_capture = False
        self.image_meta = []
        self.image_bytes = []
        self.image_bytes_active = False

    def _finish_notify(self) -> dict[str, Any] | None:
        strings = self.top_strings
        event = None
        if len(strings) >= 4:
            event = {
                "type": "notify",
                "sender": header_value(self.header, "sender"),
                "serial": int(header_value(self.header, "serial") or 0),
                "appName": strings[0],
                "appIcon": strings[1],
                "summary": strings[2],
                "body": strings[3],
                "desktopEntry": normalize_desktop_entry(self.desktop_entry),
                "replacesId": self.replaces_id,
                "imageData": self.image_data,
            }
        self.mode = ""
        return event

    def feed(self, line: str) -> dict[str, Any] | None:
        stripped = line.strip()

        if stripped.startswith("method call ") and "interface=org.freedesktop.Notifications" in stripped and "member=Notify" in stripped:
            self._start_notify(stripped)
            return None

        if stripped.startswith("method return "):
            self.mode = "return"
            self.header = stripped
            self.return_uint = None
            return None

        if stripped.startswith("signal ") and "interface=org.freedesktop.Notifications" in stripped and "member=NotificationClosed" in stripped:
            self.mode = "closed"
            self.header = stripped
            self.closed_values = []
            return None

        if self.mode == "return":
            if stripped.startswith("uint32 "):
                try:
                    value = int(stripped.split(None, 1)[1])
                except (ValueError, IndexError):
                    self.mode = ""
                    return None
                event = {
                    "type": "return",
                    "destination": header_value(self.header, "destination"),
                    "replySerial": int(header_value(self.header, "reply_serial") or 0),
                    "notificationId": value,
                }
                self.mode = ""
                return event
            # Any new bus message means this return was unrelated/no uint32.
            if stripped.startswith(("method call ", "signal ", "error ", "method return ")):
                self.mode = ""
            return None

        if self.mode == "closed":
            if stripped.startswith("uint32 "):
                try:
                    self.closed_values.append(int(stripped.split(None, 1)[1]))
                except (ValueError, IndexError):
                    pass
                if len(self.closed_values) >= 2:
                    event = {
                        "type": "closed",
                        "notificationId": self.closed_values[0],
                        "reason": self.closed_values[1],
                    }
                    self.mode = ""
                    return event
            return None

        if self.mode != "notify":
            return None

        if self.depth == 0 and self.top_arrays_completed >= 2 and stripped.startswith("int32 "):
            return self._finish_notify()

        if self.depth == 0 and stripped.startswith("uint32 "):
            try:
                self.replaces_id = int(stripped.split(None, 1)[1])
            except (ValueError, IndexError):
                self.replaces_id = 0

        if self.depth == 0 and stripped.startswith("string "):
            self.top_strings.append(parse_quoted(stripped[len("string "):]))
            return None

        if self.depth > 0 and stripped == 'string "desktop-entry"':
            self.expect_desktop_entry_value = True
        if self.depth > 0 and stripped in {'string "image-data"', 'string "image_data"'}:
            self.image_capture = True
            self.image_meta = []
            self.image_bytes = []
            self.image_bytes_active = False

        if self.image_capture and not self.image_bytes_active:
            if stripped.startswith("int32 "):
                try:
                    self.image_meta.append(int(stripped.split(None, 1)[1]))
                except (ValueError, IndexError):
                    pass
            elif stripped.startswith("boolean "):
                self.image_meta.append(stripped.split(None, 1)[1].lower() == "true")

        if self.expect_desktop_entry_value:
            match = re.search(r"variant\s+string\s+(\".*\")\s*$", stripped)
            if match:
                self.desktop_entry = parse_quoted(match.group(1))
                self.expect_desktop_entry_value = False

        if stripped.startswith("array of bytes") and stripped.endswith("["):
            if self.image_capture:
                self.image_bytes_active = True
            self.depth += 1
            return None
        if stripped.startswith("array ") and stripped.endswith("["):
            self.depth += 1
            return None

        if self.image_bytes_active and stripped and stripped != "]":
            for token in stripped.split():
                if re.fullmatch(r"[0-9a-fA-F]{2}", token):
                    self.image_bytes.append(int(token, 16))

        if stripped == "]" and self.depth > 0:
            was_image_bytes = self.image_bytes_active
            self.depth -= 1
            if was_image_bytes:
                self.image_bytes_active = False
                if len(self.image_meta) >= 6:
                    self.image_data = {
                        "width": int(self.image_meta[0]),
                        "height": int(self.image_meta[1]),
                        "rowstride": int(self.image_meta[2]),
                        "hasAlpha": bool(self.image_meta[3]),
                        "bitsPerSample": int(self.image_meta[4]),
                        "channels": int(self.image_meta[5]),
                        "data": self.image_bytes,
                    }
                self.image_capture = False
            if self.depth == 0:
                self.top_arrays_completed += 1
            return None

        return None




# Backward-compatible parser name used by the Phase 15.3d.2a contract tests.
NotifyParser = BusParser


def boot_id() -> str:
    try:
        return Path("/proc/sys/kernel/random/boot_id").read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def load_initial_events(out: Path) -> list[dict[str, Any]]:
    try:
        payload = json.loads(out.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if not isinstance(payload, dict):
        return []
    stored_boot = str(payload.get("bootId", ""))
    # Legacy state without a boot id is accepted once for backward compatibility.
    # Once rewritten, reboot boundaries are deterministic.
    if stored_boot and boot_id() and stored_boot != boot_id():
        return []
    events = payload.get("events", [])
    if not isinstance(events, list):
        return []
    return trim_events([e for e in events if isinstance(e, dict)], int(time.time()))


def write_events(out: Path, events: list[dict[str, Any]]) -> None:
    atomic_write_json(out, {"version": 1, "bootId": boot_id(), "updatedAt": int(time.time()), "events": events})


def trim_events(events: list[dict[str, Any]], now: int) -> list[dict[str, Any]]:
    cutoff = now - EVENT_TTL_SECONDS
    filtered: list[dict[str, Any]] = []
    per_app: dict[str, int] = {}
    for old in events:
        if int(old.get("timestamp", 0)) < cutoff:
            continue
        old_app = str(old.get("appId", ""))
        count = per_app.get(old_app, 0)
        if count >= MAX_EVENTS_PER_APP:
            continue
        per_app[old_app] = count + 1
        filtered.append(old)
    return filtered


def main() -> int:
    quiet = "--quiet" in sys.argv[1:]
    root = Path(__file__).resolve().parent.parent
    if shutil.which("dbus-monitor") is None:
        if not quiet:
            print("caelestia-webapps: dbus-monitor fehlt (Paket dbus).", file=sys.stderr)
        return 30

    lock = lock_path()
    lock.parent.mkdir(parents=True, exist_ok=True)
    lock_handle = lock.open("a+")
    try:
        fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        # Another watcher already owns the runtime source. This is success for
        # autostart callers and prevents duplicate event ingestion.
        return 0

    pid = pid_path()
    pid.parent.mkdir(parents=True, exist_ok=True)
    pid.write_text(str(os.getpid()) + "\n", encoding="utf-8")

    try:
        eligible = load_eligible_app_ids(root)
    except Exception as exc:  # noqa: BLE001
        if not quiet:
            print(f"caelestia-webapps: Notification-Watcher: {exc}", file=sys.stderr)
        return 20

    out = state_path()
    events = load_initial_events(out)
    write_events(out, events)

    if not quiet:
        print(
            "caelestia-webapps: Real-Notification-Watcher aktiv "
            f"({', '.join(sorted(eligible)) or 'keine Apps'}).",
            file=sys.stderr,
            flush=True,
        )
        print(f"caelestia-webapps: Statusdatei: {out}", file=sys.stderr, flush=True)

    # We need Notify calls, NotificationClosed signals and method returns. The
    # return carries the server-assigned id required to correlate close signals.
    proc = subprocess.Popen(
        [
            "dbus-monitor", "--session",
            "type='method_call',interface='org.freedesktop.Notifications',member='Notify'",
            "type='signal',interface='org.freedesktop.Notifications',member='NotificationClosed'",
            "type='method_return'",
        ],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        bufsize=1,
    )

    stopping = False

    def stop(_signum: int, _frame: object) -> None:
        nonlocal stopping
        stopping = True
        if proc.poll() is None:
            proc.terminate()

    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)

    parser = BusParser()
    pending: dict[tuple[str, int], str] = {}
    sequence = 0

    assert proc.stdout is not None
    try:
        for line in proc.stdout:
            parsed = parser.feed(line)
            if parsed is None:
                if stopping:
                    break
                continue

            kind = parsed.get("type")
            now = int(time.time())

            if kind == "notify":
                app_id = str(parsed.get("desktopEntry", ""))
                if not app_id or app_id not in eligible:
                    continue

                replaces_id = int(parsed.get("replacesId", 0) or 0)
                if replaces_id > 0:
                    replaced = [e for e in events if int(e.get("notificationId", 0) or 0) == replaces_id]
                    for old in replaced:
                        remove_cached_image(str(old.get("image", "")))
                    events = [e for e in events if int(e.get("notificationId", 0) or 0) != replaces_id]

                sequence += 1
                item_id = f"dbus-{int(time.time() * 1000)}-{sequence}"
                image_path = ""
                image_data = parsed.get("imageData")
                if isinstance(image_data, dict):
                    candidate = image_cache_dir() / f"{app_id}-{item_id}.png"
                    if write_raw_notification_png(candidate, image_data):
                        image_path = str(candidate)

                item = {
                    "id": item_id,
                    "appId": app_id,
                    "title": str(parsed.get("summary", "")),
                    "text": str(parsed.get("body", "")),
                    "timestamp": now,
                    "image": image_path,
                    "actions": [],
                    "source": "freedesktop-notify",
                    "notificationId": 0,
                }

                duplicate = next(
                    (
                        old for old in events[:3]
                        if old.get("appId") == app_id
                        and old.get("title") == item["title"]
                        and old.get("text") == item["text"]
                        and now - int(old.get("timestamp", 0)) <= 2
                    ),
                    None,
                )
                if duplicate is None:
                    events.insert(0, item)
                    pending[(str(parsed.get("sender", "")), int(parsed.get("serial", 0) or 0))] = item_id
                events = trim_events(events, now)
                write_events(out, events)
                if not quiet:
                    print(f"caelestia-webapps: {app_id}: {item['title']} — {item['text']}", file=sys.stderr, flush=True)
                continue

            if kind == "return":
                key = (str(parsed.get("destination", "")), int(parsed.get("replySerial", 0) or 0))
                item_id = pending.pop(key, "")
                if not item_id:
                    continue
                notification_id = int(parsed.get("notificationId", 0) or 0)
                changed = False
                for item in events:
                    if item.get("id") == item_id:
                        item["notificationId"] = notification_id
                        changed = True
                        break
                if changed:
                    write_events(out, events)
                continue

            if kind == "closed":
                notification_id = int(parsed.get("notificationId", 0) or 0)
                removed = [e for e in events if int(e.get("notificationId", 0) or 0) == notification_id]
                before = len(events)
                events = [e for e in events if int(e.get("notificationId", 0) or 0) != notification_id]
                if len(events) != before:
                    for old in removed:
                        remove_cached_image(str(old.get("image", "")))
                    write_events(out, events)
                    if not quiet:
                        print(f"caelestia-webapps: notification {notification_id} geschlossen", file=sys.stderr, flush=True)
                continue
    finally:
        if proc.poll() is None:
            proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
        try:
            if pid.read_text(encoding="utf-8").strip() == str(os.getpid()):
                pid.unlink(missing_ok=True)
        except OSError:
            pass
        fcntl.flock(lock_handle.fileno(), fcntl.LOCK_UN)
        lock_handle.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
