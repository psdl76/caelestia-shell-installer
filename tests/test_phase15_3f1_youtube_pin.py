#!/usr/bin/env python3
from pathlib import Path
root = Path(__file__).resolve().parents[1]
pop = (root/'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
bar = (root/'integrations/caelestia/plugin/YouTubeBarEntry.qml').read_text()
yt = (root/'integrations/caelestia/plugin/YouTubePopout.qml').read_text()
ytm = (root/'integrations/caelestia/plugin/YouTubeMusicPopout.qml').read_text()
assert 'property bool pinSupported: false' in pop
assert 'property bool pinned: false' in pop
# The detached surface must be owned by the persistent bar entry, never the
# transient popout object which Caelestia unloads when the pointer leaves it.
assert 'PanelWindow {' not in pop
assert 'PanelWindow {' in bar
assert 'exclusionMode: ExclusionMode.Ignore' in bar
assert 'aboveWindows: true' in bar
assert 'text: "push_pin"' in pop
assert 'text: "keep_off"' in bar
assert 'captureSource: root.mediaToplevel' in bar
assert 'pin-state' in pop and 'pin-set' in pop
assert 'pin-state' in bar and 'pin-set' in bar
assert 'pinSupported: true' in yt
assert 'pinSupported: true' not in ytm
print('Phase 15.3f.1-fix1 persistent YouTube pinned preview: PASS')
