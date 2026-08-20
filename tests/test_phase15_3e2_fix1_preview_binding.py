#!/usr/bin/env python3
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
qml = (ROOT / 'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
assert 'import Quickshell.Hyprland' in qml
assert 'Hyprland.toplevels?.values' in qml
assert 'ipc.class' in qml and 'ipc.initialClass' in qml
assert 'top?.wayland' in qml
assert 'ToplevelManager.toplevels?.values' in qml
assert 'function restartLivePreview()' in qml
assert 'Qt.callLater' in qml
assert 'onStopped: root.restartLivePreview()' in qml
assert ('Loader {' in qml and 'id: livePreviewLoader' in qml) or ('VideoCropView {' in qml and 'id: livePreviewLoader' in qml)
assert 'root.livePreviewHasContent' in qml
print('Phase 15.3e.2-fix1 deterministic live-preview binding: PASS')
