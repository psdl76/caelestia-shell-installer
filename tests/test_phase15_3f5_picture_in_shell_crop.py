#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
view = (root / 'integrations/caelestia/plugin/VideoCropView.qml').read_text()
pop = (root / 'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
bar = (root / 'integrations/caelestia/plugin/YouTubeBarEntry.qml').read_text()
cli = (root / 'bin/caelestia-webapps').read_text()

assert 'property var normalizedRect' in view
assert 'property var viewport' in view
assert 'readonly property bool cropAvailable' in view
assert 'const scale = Math.max(targetWidth / rw, targetHeight / rh)' in view
assert 'clip: true' in view
assert 'ScreencopyView {' in view
assert 'Behavior on x' in view and 'Behavior on width' in view

# Both transient popout and persistent pinned surface use exactly the same crop renderer.
assert 'VideoCropView {' in pop
assert 'normalizedRect: root.videoRect' in pop
assert 'viewport: root.videoViewport' in pop
assert 'VideoCropView {' in bar
assert 'normalizedRect: root.videoRect' in bar
assert 'viewport: root.videoViewport' in bar
assert 'liveCaptureGeometry' not in bar

# DOM timing remains authoritative when BiDi is available.
assert 'state["videoRect"] = browser.get("normalized", {})' in cli
assert 'state["duration"] = duration' in cli
assert 'state["position"] = max(0.0, min(duration, position))' in cli
assert 'state["progress"] = max(0.0, min(1.0, state["position"] / duration))' in cli
assert 'state["domPlaying"]' in cli

print('Phase 15.3f.5 Picture-in-Shell crop renderer: PASS')
