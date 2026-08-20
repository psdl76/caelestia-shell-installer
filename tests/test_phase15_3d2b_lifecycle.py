#!/usr/bin/env python3
from pathlib import Path
import importlib.util
import json
import tempfile

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('nw', ROOT/'scripts/notification_watch.py')
nw=importlib.util.module_from_spec(spec); spec.loader.exec_module(nw)

p=nw.BusParser()
notify='''method call time=1 sender=:1.28 -> destination=:1.11 serial=58 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=Notify
   string "Firefox"
   uint32 0
   string ""
   string "Carmen Seidl"
   string "Okay"
   array [
      string "default"
      string "Activate"
   ]
   array [
      dict entry(
         string "desktop-entry"
         variant             string "whatsapp"
      )
   ]
   int32 -1
'''
e=None
for line in notify.splitlines(True):
    got=p.feed(line)
    if got: e=got
assert e and e['desktopEntry']=='whatsapp' and e['serial']==58 and e['sender']==':1.28' and e['replacesId']==0

r=None
for line in '''method return time=1 sender=:1.11 -> destination=:1.28 serial=100 reply_serial=58\n   uint32 42\n'''.splitlines(True):
    got=p.feed(line)
    if got: r=got
assert r=={'type':'return','destination':':1.28','replySerial':58,'notificationId':42}

c=None
for line in '''signal time=2 sender=:1.11 -> destination=(null destination) serial=101 path=/org/freedesktop/Notifications; interface=org.freedesktop.Notifications; member=NotificationClosed\n   uint32 42\n   uint32 2\n'''.splitlines(True):
    got=p.feed(line)
    if got: c=got
assert c=={'type':'closed','notificationId':42,'reason':2}

cli=(ROOT/'bin/caelestia-webapps').read_text()
assert 'ensure_notification_watcher()' in cli
assert '[sys.executable, str(NOTIFICATION_WATCH_TOOL), "--quiet"]' in cli
watch=(ROOT/'scripts/notification_watch.py').read_text()
assert 'LOCK_EX | fcntl.LOCK_NB' in watch
assert "member='NotificationClosed'" in watch
assert "type='method_return'" in watch
assert 'replaces_id > 0' in watch
print('Phase 15.3d.2b notification lifecycle: PASS')
