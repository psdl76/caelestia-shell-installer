#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
pop=(root/'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
yt=(root/'integrations/caelestia/plugin/YouTubePopout.qml').read_text()
ytm=(root/'integrations/caelestia/plugin/YouTubeMusicPopout.qml').read_text()
cli=(root/'bin/caelestia-webapps').read_text()
theme=(root/'integrations/caelestia/plugin/PluginTheme.qml').read_text()
conf=(root/'apps/youtube-music.conf').read_text()
for needle in [
    'property string mediaPresentation: "auto"',
    'root.mediaPresentation === "artwork"',
    'root.useLivePreview',
    'theme.accent',
    'theme.barIcon',
    'id: artworkImage',
    'root.formatTime(root.status.state?.position ?? 0)',
    'root.formatTime(root.status.state?.duration ?? 0)',
    'root.visualizerPhase',
    'play-pause',
]:
    assert needle in pop, needle
assert 'appId: "youtube-music"' not in pop
assert 'mediaPresentation: "live_preview"' in yt
assert 'mediaPresentation: "artwork"' in ytm
assert '"position": position_seconds' in cli
assert '"duration": length_seconds' in cli
assert 'STATUS_INTEGRATION_CAPABILITIES="now_playing;playback_controls;artwork;"' in conf
for role in ['primary','secondary','surfaceContainerLow','surfaceContainerHigh','onSurface','onSurfaceVariant']:
    assert role in theme, role
print('Phase 15.3e.4 themed adaptive media card: PASS')
