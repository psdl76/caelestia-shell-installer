#!/usr/bin/env python3
import struct
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets/branding"
SVG = BRANDING / "caelestia-webapps.svg"

svg_text = SVG.read_text(encoding="utf-8")
root = ET.fromstring(svg_text)
assert root.tag == "{http://www.w3.org/2000/svg}svg"
assert root.attrib["viewBox"] == "0 0 1024 1024"
assert "<image" not in svg_text
assert "data:image" not in svg_text
assert svg_text.count("linearGradient") >= 4
assert "An open rounded portal with three emerging WebApp tiles" in svg_text


def png_header(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()[:33]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    assert data[12:16] == b"IHDR", path
    width, height, _depth, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, color_type


source = BRANDING / "logo-source.png"
assert png_header(source) == (1024, 1024, 6)

for size in (16, 24, 32, 48, 64, 128, 256, 512):
    path = BRANDING / "png" / f"caelestia-webapps-{size}.png"
    assert png_header(path) == (size, size, 6), path

print("PASS: transparent vector branding master and launcher exports")
