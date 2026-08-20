from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
cli = (ROOT / "bin/caelestia-webapps").read_text()
qml = (ROOT / "integrations/caelestia/plugin/VideoCropView.qml").read_text()

assert "def _browser_video_state_query" in cli
assert "def _browser_video_state_result" in cli
assert "browser-video" in cli
assert "fcntl.LOCK_EX | fcntl.LOCK_NB" in cli
assert "cache-after-wait" in cli
assert "stale-cache-fallback" in cli
assert "CAELESTIA_WEBAPPS_VIDEO_CACHE_SECONDS" in cli
assert "rememberedRect" in qml
assert "incomingCropValid" in qml
assert "cropHoldMs: 6000" in qml
assert "effectiveRect" in qml
print("Phase 15.3f.5-fix1 serialized BiDi crop cache + stable presentation: PASS")
