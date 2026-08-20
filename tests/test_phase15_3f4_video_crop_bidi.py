#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import importlib.machinery
import importlib.util
import json
import socket
import struct
import threading
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / "bin/caelestia-webapps"
GENERIC = ROOT / "integrations/caelestia/plugin/GenericStatusPopout.qml"
YOUTUBE_BAR = ROOT / "integrations/caelestia/plugin/YouTubeBarEntry.qml"
YOUTUBE_CONF = ROOT / "apps/youtube.conf"
VIDEO_CROP_VIEW = ROOT / "integrations/caelestia/plugin/VideoCropView.qml"
LAUNCHER = ROOT / "templates/launcher.sh.tpl"

conf = YOUTUBE_CONF.read_text()
launcher = LAUNCHER.read_text()
generic = GENERIC.read_text()
ytbar = YOUTUBE_BAR.read_text()
video_crop_view = VIDEO_CROP_VIEW.read_text()
cli_text = CLI.read_text()

assert 'BROWSER_BRIDGE_PORT="9341"' in conf
assert '--remote-debugging-port' in launcher
assert 'browser-video-state' in cli_text
assert 'videoRect' in generic and 'videoViewport' in generic
assert 'videoRect' in generic and 'videoViewport' in generic
assert ('liveCaptureGeometry' in generic) or ('VideoCropView {' in generic)
assert ('liveCaptureGeometry' in ytbar) or ('VideoCropView {' in ytbar)
assert ('liveCaptureGeometry' in video_crop_view) or ('captureGeometry' in video_crop_view)
assert 'firefox-webdriver-bidi' in cli_text

loader = importlib.machinery.SourceFileLoader("cw_phase15_3f4", str(CLI))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


def recv_exact(conn: socket.socket, count: int) -> bytes:
    data = b""
    while len(data) < count:
        data += conn.recv(count - len(data))
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
server.listen(1)
port = server.getsockname()[1]


def fake_bidi_server() -> None:
    conn, _ = server.accept()
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

    for _ in range(3):
        req = recv_json_frame(conn)
        if req["method"] == "session.new":
            result = {"id": req["id"], "type": "success", "result": {"sessionId": "test", "capabilities": {}}}
        elif req["method"] == "browsingContext.getTree":
            result = {
                "id": req["id"], "type": "success",
                "result": {"contexts": [{"context": "yt", "url": "https://www.youtube.com/watch?v=test", "children": []}]},
            }
        else:
            state = {
                "available": True,
                "x": 96, "y": 54, "width": 1280, "height": 720,
                "viewportWidth": 1920, "viewportHeight": 1080,
                "position": 42.0, "duration": 120.0,
                "paused": False, "ended": False,
            }
            result = {
                "id": req["id"], "type": "success",
                "result": {"result": {"type": "string", "value": json.dumps(state)}},
            }
        send_json_frame(conn, result)
    conn.close()
    server.close()


threading.Thread(target=fake_bidi_server, daemon=True).start()
state = module._browser_video_state({
    "id": "youtube",
    "url": "https://www.youtube.com/",
    "browserBridge": {"kind": "webdriver-bidi", "port": port},
})

assert state is not None
assert state["source"] == "firefox-webdriver-bidi"
assert abs(state["normalized"]["x"] - 0.05) < 0.001
assert abs(state["normalized"]["width"] - (1280 / 1920)) < 0.001
assert state["position"] == 42.0
assert state["duration"] == 120.0

print("Phase 15.3f.4 Firefox BiDi video crop + DOM timing: PASS")
