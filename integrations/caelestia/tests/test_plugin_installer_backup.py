import os
import shutil
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
installer = root / "tools" / "install-plugin-test.sh"

with tempfile.TemporaryDirectory() as td:
    base = Path(td)
    home = base / "home"
    config = base / "config"
    home.mkdir()
    env = os.environ.copy()
    env["HOME"] = str(home)
    env["XDG_CONFIG_HOME"] = str(config)

    # First install.
    subprocess.run([str(installer)], env=env, check=True, capture_output=True, text=True)
    plugin_root = config / "caelestia" / "plugins"
    dest = plugin_root / "webapps"
    backup_root = config / "caelestia" / "plugin-backups"
    assert (dest / "manifest.json").is_file()

    # Simulate the historical PoC3 bug: a backup with the same manifest remains
    # under the discovery root. The new installer must evacuate it automatically.
    legacy = plugin_root / "webapps.backup.legacy"
    shutil.copytree(dest, legacy)
    assert (legacy / "manifest.json").is_file()

    # Second install backs up the active plugin and migrates the legacy backup.
    subprocess.run([str(installer)], env=env, check=True, capture_output=True, text=True)

    manifests = list(plugin_root.glob("*/manifest.json"))
    assert manifests == [dest / "manifest.json"], manifests
    assert not any(plugin_root.glob("webapps.backup.*"))

    backups = list(backup_root.glob("webapps.backup.*"))
    assert len(backups) >= 2, backups
    assert all((p / "manifest.json").is_file() for p in backups)

    staging = config / "caelestia" / ".plugin-staging"
    assert not staging.exists() or not any(staging.iterdir())

print("Phase 15.2 plugin PoC4 installer backup isolation: PASS")
