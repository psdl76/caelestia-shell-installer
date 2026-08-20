#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
cli=(ROOT/'bin/caelestia-webapps').read_text()
qml=(ROOT/'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
manifest=(ROOT/'integrations/caelestia/plugin/manifest.json').read_text()
assert 'def media_status_for_app' in cli
assert 'xesam:url' in cli and 'mpris:artUrl' in cli and 'playerctl' in cli
assert 'Image.PreserveAspectCrop' in qml and 'state?.progress' in qml
assert 'webapp-youtube' in manifest
assert (ROOT/'integrations/caelestia/plugin/YouTubeBarEntry.qml').exists()
print('Phase 15.3e.1 generic MPRIS now playing: PASS')
