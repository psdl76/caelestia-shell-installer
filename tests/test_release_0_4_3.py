#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
README = (ROOT / "README.md").read_text(encoding="utf-8")
ARCH_PKGBUILD = (ROOT / "packaging/arch/PKGBUILD.in").read_text(encoding="utf-8")
AUR_PKGBUILD = (ROOT / "packaging/aur/PKGBUILD").read_text(encoding="utf-8")
RELEASE = (ROOT / "docs/releases/RELEASE_0.4.3.md").read_text(encoding="utf-8")

assert VERSION == "0.4.3"
assert README.startswith("# Caelestia WebApps 0.4.3\n")
assert "run_release_0_4_3_gate.sh" in README
assert "PUBLIC RELEASE — LIVE VERIFIED" in RELEASE
assert "Real Hyprland lifecycle: passed" in RELEASE
assert "pkgver=0.4.3" in ARCH_PKGBUILD
assert "pkgver=0.4.3" in AUR_PKGBUILD

for name in (
    "make-runtime-tarball.sh",
    "install-core.sh",
    "uninstall-core.sh",
    "build-arch-package.sh",
):
    script = ROOT / "packaging" / name
    assert script.read_bytes().startswith(b"#!/usr/bin/env bash\n"), name
    assert script.stat().st_mode & 0o111, name

tar_script = (ROOT / "packaging/make-runtime-tarball.sh").read_text(encoding="utf-8")
for required in ('--sort=name', '--mtime="@$SOURCE_DATE_EPOCH"', '--owner=0', '--group=0'):
    assert required in tar_script, required

print("PASS: release 0.4.3 metadata and deterministic packaging contract")
