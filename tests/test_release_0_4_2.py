#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
README = (ROOT / "README.md").read_text(encoding="utf-8")
PKGBUILD = (ROOT / "packaging/arch/PKGBUILD.in").read_text(encoding="utf-8")
RELEASE = (ROOT / "docs/releases/RELEASE_0.4.2.md").read_text(encoding="utf-8")
PHASE = (ROOT / "docs/phases/phase-20/PHASE20_1_PRODUCT_BRANDING.md").read_text(encoding="utf-8")

assert VERSION == "0.4.2"
assert README.startswith("# Caelestia WebApps 0.4.2\n")
assert "run_release_0_4_2_gate.sh" in README
assert "PUBLIC RELEASE — VERIFIED" in RELEASE
assert "passed with distinction" in RELEASE
assert "Status: **LIVE ACCEPTED / FROZEN**" in PHASE
assert "pkgver=0.4.2" in PKGBUILD
assert "caelestia-webapps.svg" in PKGBUILD

for name in ("make-runtime-tarball.sh", "build-arch-package.sh"):
    script = ROOT / "packaging" / name
    assert script.read_bytes().startswith(b"#!/usr/bin/env bash\n"), name
    assert script.stat().st_mode & 0o111, name

print("PASS: release 0.4.2 branding metadata and packaging helpers")
