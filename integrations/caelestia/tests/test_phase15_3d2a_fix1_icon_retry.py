#!/usr/bin/env python3
from pathlib import Path

plugin = Path(__file__).resolve().parents[1] / "plugin"
entry = (plugin / "GenericStatusBarEntry.qml").read_text()
assert "id: iconRetryTimer" in entry
assert "running: root.iconSource.length === 0" in entry
assert "onTriggered: root.reloadApp()" in entry
assert "if (root.iconSource.length === 0)" in entry
assert "layer.enabled: status === Image.Ready" in entry
assert "active: root.iconSource.length > 0" in entry
assert "colorizationColor: theme.barIcon" in entry
print("Phase 15.3d.2a-fix1 icon resolution retry: PASS")
