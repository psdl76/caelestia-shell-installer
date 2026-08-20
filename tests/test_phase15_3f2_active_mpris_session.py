#!/usr/bin/env python3
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path

root = Path(__file__).resolve().parents[1]
loader = SourceFileLoader("caelestia_webapps_cli", str(root / "bin" / "caelestia-webapps"))
spec = spec_from_loader(loader.name, loader)
mod = module_from_spec(spec)
loader.exec_module(mod)

states = [
    {"player": "firefox.stale", "playbackStatus": "paused", "position": 140.0, "playing": False},
    {"player": "firefox.audible", "playbackStatus": "playing", "position": 12.0, "playing": True},
]
selected = mod._select_media_state(states)
assert selected["player"] == "firefox.audible", selected

states = [
    {"player": "firefox.old", "playbackStatus": "paused", "position": 5.0, "playing": False},
    {"player": "firefox.current", "playbackStatus": "paused", "position": 42.0, "playing": False},
]
selected = mod._select_media_state(states)
assert selected["player"] == "firefox.current", selected

print("Phase 15.3f.2 active MPRIS session selection: PASS")
