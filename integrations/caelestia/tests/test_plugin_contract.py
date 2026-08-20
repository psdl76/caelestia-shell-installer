import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
plugin = root / "plugin"
manifest = json.loads((plugin / "manifest.json").read_text())

assert manifest["name"] == "webapps"
assert manifest["author"] == "caelestia_webapps"
assert manifest["requires"] == ">=2.2.0"

plugin_id = f'{manifest["author"]}/{manifest["name"]}'.lower()
assert plugin_id == "caelestia_webapps/webapps"

eps = manifest["entryPoints"]
assert any(e["type"] == "bar-entry"
           and e["properties"]["name"] == "webapps"
           and e["source"] == "WebAppsBarEntry.qml" for e in eps)
assert any(e["type"] == "bar-popout"
           and e["properties"]["entry"] == "webapps"
           and e["source"] == "WebAppsPopout.qml" for e in eps)

for qml in ["WebAppsBarEntry.qml", "WebAppsPopout.qml"]:
    text = (plugin / qml).read_text()
    assert "import qs." not in text
    assert "import Caelestia.Config" not in text
    assert "import Caelestia.Services" not in text

popout = (plugin / "WebAppsPopout.qml").read_text()
assert '"/usr/bin/env"' in popout
assert '"PATH=" + root.processPath' in popout
assert '"caelestia-webapps"' in popout
assert 'root.cliCommand(["list"])' in popout
assert 'root.cliCommand(["launch", appId])' in popout
assert 'root.managerCommand()' in popout
assert "appletVisible === true" in popout
assert "app.installed === true" in popout

enable = (root / "tools" / "set-plugin-enabled.py").read_text()
assert 'PLUGIN_ID = "caelestia_webapps/webapps"' in enable

assert 'import Quickshell\n' in popout
assert 'environment: ({ PATH: root.processPath })' not in popout
assert 'home + "/.local/bin"' in popout
assert '["sh", "-c"' not in popout

print("Phase 15.2 plugin PoC7.1 resolver contract: PASS")

installer = (root / "tools" / "install-plugin-test.sh").read_text()
assert 'BACKUP_ROOT="$CAELESTIA_CONFIG_ROOT/plugin-backups"' in installer
assert 'STAGE_ROOT="$CAELESTIA_CONFIG_ROOT/.plugin-staging"' in installer
assert '"$DEST_ROOT"/webapps.backup.*' in installer
assert 'mktemp -d "$STAGE_ROOT/webapps.XXXXXX"' in installer

theme = (plugin / "PluginTheme.qml").read_text()
assert 'caelestia/theme/caelestia-webapps.json' in theme
assert 'import qs.' not in theme
assert 'import Caelestia.' not in theme
assert 'FileView' in theme
assert 'watchChanges: true' in theme
assert 'PluginTheme { id: theme }' in popout
assert 'PluginTheme { id: theme }' in (plugin / "WebAppsBarEntry.qml").read_text()
assert 'color: "#ee1b1b1f"' not in popout

bar = (plugin / "WebAppsBarEntry.qml").read_text()
assert "import caelestia_webapps.webapps" in bar
assert "import caelestia_webapps.webapps" in popout
assert 'readonly property color outline:' in theme
assert 'border.color: managerHover.hovered ? theme.outlineHover : theme.outline' in popout
assert manifest["version"] == "0.9.3"
assert "implicitWidth: 316" in popout
assert "implicitHeight: isNotification || isMedia ? 62 : 44" in popout
assert "sourceSize.width: 26" in popout
assert "implicitHeight: 38" in popout
assert "font.pixelSize: 15" in popout
assert "width: 28" in bar
print("Phase 15.2 plugin PoC7 visual-polish contract: PASS")
