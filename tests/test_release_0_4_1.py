#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
README = (ROOT / "README.md").read_text(encoding="utf-8")
PKGBUILD = (ROOT / "packaging/arch/PKGBUILD.in").read_text(encoding="utf-8")
RELEASE = (ROOT / "docs/releases/RELEASE_0.4.1.md").read_text(encoding="utf-8")
PHASE = (ROOT / "docs/phases/phase-18/PHASE18_1_MANAGER_LOCALIZATION.md").read_text(encoding="utf-8")

assert VERSION == "0.4.1"
assert README.startswith("# Caelestia WebApps 0.4.1\n")
assert "CAELESTIA_WEBAPPS_LANGUAGE=de" in README
assert "CAELESTIA_WEBAPPS_LANGUAGE=en" in README
assert "LOCAL / PRIVATE RELEASE CANDIDATE" in RELEASE
assert "Real installed lifecycle: pending" in RELEASE
assert "Status: **ACCEPTED / FROZEN**" in PHASE
assert "English live Manager acceptance" in RELEASE
assert "German live Manager acceptance" in RELEASE

for name in ("make-runtime-tarball.sh", "build-arch-package.sh"):
    script = ROOT / "packaging" / name
    assert script.read_bytes().startswith(b"#!/usr/bin/env bash\n"), name
    assert script.stat().st_mode & 0o111, name

assert 'VERSION="${1:-$(<"$ROOT/VERSION")}"' in (ROOT / "packaging/make-runtime-tarball.sh").read_text(encoding="utf-8")
assert 'VERSION="$(<"$ROOT/VERSION")"' in (ROOT / "packaging/build-arch-package.sh").read_text(encoding="utf-8")
assert "pkgver=0.4.1" in PKGBUILD
assert 'url=""' in PKGBUILD
assert "OWNER" not in PKGBUILD
assert "LICENSE-PENDING" in PKGBUILD
assert "cp -a --no-preserve=ownership" in PKGBUILD

print("PASS: release 0.4.1 candidate metadata and packaging helpers")
