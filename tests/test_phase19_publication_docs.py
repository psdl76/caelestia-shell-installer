#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
README = (ROOT / "README.md").read_text(encoding="utf-8")
PHASE = (ROOT / "docs/phases/phase-19/PHASE19_AUR_COMMUNITY_LAUNCH.md").read_text(encoding="utf-8")
LAUNCH = (ROOT / "docs/releases/COMMUNITY_LAUNCH_0.4.1.md").read_text(encoding="utf-8")

assert "unofficial community project" in README
assert "An AUR package named `caelestia-webapps` is being prepared." in README
assert "ACCOUNT REGISTRATION BLOCKED" in PHASE
assert "no manual onboarding path" in PHASE
assert "clean Arch chroot build completed successfully" in PHASE
assert "does not invalidate the package build" in PHASE
assert "Do not paste the AUR command" in LAUNCH
assert "Caelestia GitHub — Show and tell" in LAUNCH
assert "Caelestia Discord" in LAUNCH
assert "Hyprland community" in LAUNCH
assert "German CachyOS/Arch post" in LAUNCH
assert "not an official Caelestia component" in LAUNCH

for image in ("manager-catalog.png", "manager-webapp-info.png"):
    path = ROOT / "media" / image
    assert path.is_file(), image
    assert path.stat().st_size < 500_000, image

print("PASS: Phase 19 publication copy, safeguards and presentation media")
