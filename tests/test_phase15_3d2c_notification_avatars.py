#!/usr/bin/env python3
from __future__ import annotations
import importlib.util
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD_PATH = ROOT / 'scripts' / 'notification_watch.py'
spec = importlib.util.spec_from_file_location('notification_watch', MOD_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)

sample = [
'method call time=1 sender=:1.2 -> destination=:1.1 serial=9 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=Notify\n',
'   string "Firefox"\n','   uint32 0\n','   string ""\n','   string "Alice"\n','   string "Hi"\n',
'   array [\n','      string "default"\n','      string "Activate"\n','   ]\n',
'   array [\n','      dict entry(\n','         string "desktop-entry"\n','         variant             string "whatsapp"\n','      )\n',
'      dict entry(\n','         string "image-data"\n','         variant             struct {\n','               int32 1\n','               int32 1\n','               int32 4\n','               boolean true\n','               int32 8\n','               int32 4\n','               array of bytes [\n','                  ff 00 00 ff\n','               ]\n','         }\n','      )\n','   ]\n','   int32 -1\n']
p = mod.BusParser(); evt=None
for line in sample:
    got=p.feed(line)
    if got: evt=got
assert evt and evt['desktopEntry']=='whatsapp'
assert evt['imageData']['width']==1 and evt['imageData']['data']==[255,0,0,255]
with tempfile.TemporaryDirectory() as td:
    out=Path(td)/'a.png'
    assert mod.write_raw_notification_png(out, evt['imageData'])
    assert out.read_bytes().startswith(b'\x89PNG\r\n\x1a\n')
qml=(ROOT/'integrations/caelestia/plugin/GenericStatusPopout.qml').read_text()
assert 'modelData?.image' in qml and 'Image.PreserveAspectCrop' in qml
print('Phase 15.3d.2c notification avatars: PASS')
