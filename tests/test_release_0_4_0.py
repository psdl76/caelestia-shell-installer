#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
README = (ROOT / "README.md").read_text(encoding="utf-8")
PKGBUILD = (ROOT / "packaging/arch/PKGBUILD.in").read_text(encoding="utf-8")
RELEASE = (ROOT / "docs/releases/RELEASE_0.4.0.md").read_text(encoding="utf-8")

assert VERSION == "0.4.0"
assert README.startswith("# Caelestia WebApps 0.4.0\n")
assert "Manager PoC" not in README
assert "Phase 17.7" in README
assert "LOCAL / PRIVATE RELEASE" in RELEASE
assert "2026-08-20" in RELEASE

for name in ("make-runtime-tarball.sh", "build-arch-package.sh"):
    script = ROOT / "packaging" / name
    assert script.read_bytes().startswith(b"#!/usr/bin/env bash\n"), name
    assert script.stat().st_mode & 0o111, name

assert 'VERSION="${1:-$(<"$ROOT/VERSION")}"' in (ROOT / "packaging/make-runtime-tarball.sh").read_text(encoding="utf-8")
assert 'VERSION="$(<"$ROOT/VERSION")"' in (ROOT / "packaging/build-arch-package.sh").read_text(encoding="utf-8")
assert "pkgver=0.4.0" in PKGBUILD
assert 'url=""' in PKGBUILD
assert "OWNER" not in PKGBUILD
assert "LICENSE-PENDING" in PKGBUILD
assert "cp -a --no-preserve=ownership" in PKGBUILD

print("PASS: release 0.4.0 metadata and directly executable packaging helpers")
