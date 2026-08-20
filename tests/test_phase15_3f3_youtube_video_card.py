#!/usr/bin/env python3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
pop=(root/'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
yt=(root/'integrations/caelestia/plugin/YouTubePopout.qml').read_text()
assert 'readonly property bool isVideoPresentation:' in pop
assert 'root.mediaPresentation === "live_preview"' in pop
assert 'visible: !root.isVideoPresentation' in pop
assert 'Audio-only activity visualizer' in pop
assert 'id: liveBadgeRow' in pop
assert 'root.status.state?.playing === true ? "LIVE" : "VIDEO"' in pop
assert 'SequentialAnimation on opacity' in pop
assert 'visible: !root.isVideoPresentation && String(root.status.state?.album ?? "").length > 0' in pop
assert 'mediaPresentation: "live_preview"' in yt
print('Phase 15.3f.3 YouTube video-first card: PASS')
