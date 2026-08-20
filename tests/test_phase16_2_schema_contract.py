from __future__ import annotations
import json, shutil, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
validator=ROOT/'scripts/validate_definitions.py'

def run(root):
    p=subprocess.run(['python3',str(validator),str(root)],text=True,capture_output=True)
    return p.returncode,json.loads(p.stdout)

rc,data=run(ROOT)
assert rc==0 and data['ok'] is True, data
assert data['stats']=={'apps':79,'featured':23,'appletCapable':21,'supported':4,'experimental':17,'defaultEnabled':0,'categories':14}

# Negative: wrong capability for adapter must be rejected.
with tempfile.TemporaryDirectory() as td:
    t=Path(td)
    shutil.copytree(ROOT/'apps',t/'apps')
    shutil.copytree(ROOT/'config',t/'config')
    p=t/'apps/whatsapp.conf'
    s=p.read_text().replace('APPLET_CAPABILITIES="notifications;badge;preview;"','APPLET_CAPABILITIES="notifications;video_crop;"')
    p.write_text(s)
    rc,data=run(t)
    assert rc==1 and any('do not belong to adapter' in e for e in data['errors']), data

# Negative: applets are frozen default-off.
with tempfile.TemporaryDirectory() as td:
    t=Path(td)
    shutil.copytree(ROOT/'apps',t/'apps')
    shutil.copytree(ROOT/'config',t/'config')
    p=t/'apps/youtube.conf'
    p.write_text(p.read_text().replace('APPLET_DEFAULT_ENABLED="false"','APPLET_DEFAULT_ENABLED="true"'))
    rc,data=run(t)
    assert rc==1 and any('default to disabled' in e for e in data['errors']), data

# Negative: primary category must be part of the multi-category list.
with tempfile.TemporaryDirectory() as td:
    t=Path(td)
    shutil.copytree(ROOT/'apps',t/'apps')
    shutil.copytree(ROOT/'config',t/'config')
    p=t/'apps/youtube.conf'
    p.write_text(p.read_text().replace('APP_CATALOG_CATEGORIES_LIST="video;google;"','APP_CATALOG_CATEGORIES_LIST="google;"'))
    rc,data=run(t)
    assert rc==1 and any('must include primary category' in e for e in data['errors']), data

print('PASS: Phase16.2 schema contract + negative tests')
