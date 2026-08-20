from pathlib import Path

root = Path(__file__).resolve().parents[1]
bar = (root / "integrations/caelestia/plugin/GenericStatusBarEntry.qml").read_text()
theme = (root / "integrations/caelestia/plugin/PluginTheme.qml").read_text()
manifest = (root / "integrations/caelestia/plugin/manifest.json").read_text()

assert "import QtQuick.Effects" in bar
assert "MultiEffect" in bar
assert "colorization: 1.0" in bar
assert "colorizationColor: theme.barIcon" in bar
assert "width: 21" in bar and "height: 21" in bar
assert "color: theme.accentContent" in bar
assert 'colour("onPrimary"' in theme
assert 'colour("secondary"' in theme
assert "readonly property color barIcon" in theme
assert '"version": "0.9.3"' in manifest
assert "import qs." not in bar
assert "import Caelestia." not in bar
print("Phase 15.3c.1 native bar icon contract: PASS")
