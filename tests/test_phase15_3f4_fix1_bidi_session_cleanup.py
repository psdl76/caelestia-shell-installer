#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import importlib.machinery
import importlib.util
import json
import os
import tempfile
import socket
import struct
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
os.environ["XDG_STATE_HOME"] = tempfile.mkdtemp(prefix="cw-bidi-cleanup-")
os.environ["CAELESTIA_WEBAPPS_VIDEO_CACHE_SECONDS"] = "0"
os.environ["CAELESTIA_WEBAPPS_VIDEO_STALE_SECONDS"] = "0"
CLI = ROOT / "bin/caelestia-webapps"
text = CLI.read_text()
assert '"session.end"' in text
assert 'diagnostics' in text
assert 'firstMatch' in text and 'alwaysMatch' in text

loader = importlib.machinery.SourceFileLoader("cw_phase15_3f4_fix1", str(CLI))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


def recv_exact(conn: socket.socket, count: int) -> bytes:
    data = b""
    while len(data) < count:
        chunk = conn.recv(count - len(data))
        if not chunk:
            raise OSError("closed")
        data += chunk
    return data


def recv_json_frame(conn: socket.socket) -> dict:
    first, second = recv_exact(conn, 2)
    length = second & 0x7F
    if length == 126:
        length = struct.unpack("!H", recv_exact(conn, 2))[0]
    elif length == 127:
        length = struct.unpack("!Q", recv_exact(conn, 8))[0]
    mask = recv_exact(conn, 4) if second & 0x80 else b""
    payload = recv_exact(conn, length)
    if mask:
        payload = bytes(byte ^ mask[i % 4] for i, byte in enumerate(payload))
    return json.loads(payload)


def send_json_frame(conn: socket.socket, payload: dict) -> None:
    data = json.dumps(payload, separators=(",", ":")).encode()
    if len(data) < 126:
        header = bytes([0x81, len(data)])
    elif len(data) <= 0xFFFF:
        header = bytes([0x81, 126]) + struct.pack("!H", len(data))
    else:
        header = bytes([0x81, 127]) + struct.pack("!Q", len(data))
    conn.sendall(header + data)


server = socket.socket()
server.bind(("127.0.0.1", 0))
server.listen(2)
port = server.getsockname()[1]
state_lock = threading.Lock()
active = False
ended = 0


def handle_connection(conn: socket.socket) -> None:
    global active, ended
    request = b""
    while b"\r\n\r\n" not in request:
        request += conn.recv(4096)
    key = next(
        line.split(b":", 1)[1].strip()
        for line in request.split(b"\r\n")
        if line.lower().startswith(b"sec-websocket-key:")
    )
    accept = base64.b64encode(hashlib.sha1(key + b"258EAFA5-E914-47DA-95CA-C5AB0DC85B11").digest())
    conn.sendall(
        b"HTTP/1.1 101 Switching Protocols\r\n"
        b"Upgrade: websocket\r\n"
        b"Connection: Upgrade\r\n"
        b"Sec-WebSocket-Accept: " + accept + b"\r\n\r\n"
    )

    while True:
        try:
            req = recv_json_frame(conn)
        except OSError:
            break
        method = req["method"]
        if method == "session.new":
            with state_lock:
                if active:
                    result = {
                        "id": req["id"], "type": "error", "error": "session not created",
                        "message": "Maximum number of active sessions",
                    }
                else:
                    active = True
                    result = {"id": req["id"], "type": "success", "result": {"sessionId": "test", "capabilities": {}}}
        elif method == "browsingContext.getTree":
            result = {
                "id": req["id"], "type": "success",
                "result": {"contexts": [{"context": "yt", "url": "https://www.youtube.com/watch?v=test", "children": []}]},
            }
        elif method == "script.evaluate":
            browser_state = {
                "available": True,
                "x": 100, "y": 50, "width": 1280, "height": 720,
                "viewportWidth": 1920, "viewportHeight": 1080,
                "position": 21.0, "duration": 90.0,
                "paused": False, "ended": False,
            }
            result = {
                "id": req["id"], "type": "success",
                "result": {"result": {"type": "string", "value": json.dumps(browser_state)}},
            }
        elif method == "session.end":
            with state_lock:
                active = False
                ended += 1
            result = {"id": req["id"], "type": "success", "result": {}}
            send_json_frame(conn, result)
            break
        else:
            result = {"id": req["id"], "type": "error", "error": "unknown command", "message": method}
        send_json_frame(conn, result)
    conn.close()


def fake_server() -> None:
    for _ in range(2):
        conn, _ = server.accept()
        handle_connection(conn)
    server.close()


threading.Thread(target=fake_server, daemon=True).start()
app = {
    "id": "youtube",
    "url": "https://www.youtube.com/",
    "browserBridge": {"kind": "webdriver-bidi", "port": port},
}
first, diag1 = module._browser_video_state_result(app)
second, diag2 = module._browser_video_state_result(app)

assert first is not None and second is not None
assert first["duration"] == 90.0 and second["position"] == 21.0
assert diag1["stage"] == "complete" and diag2["stage"] == "complete"
assert diag1["cleanup"] == "session.end" and diag2["cleanup"] == "session.end"
assert ended == 2, ended
assert active is False
print("Phase 15.3f.4-fix1 BiDi session cleanup/repeat polling: PASS")
