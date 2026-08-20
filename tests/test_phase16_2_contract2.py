from __future__ import annotations
import json, shutil, subprocess, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
VAL=ROOT/'scripts/validate_definitions.py'

def run(root: Path):
    p=subprocess.run(['python3',str(VAL),str(root)],text=True,capture_output=True)
    assert p.stdout.strip(), p.stderr
    return p.returncode,json.loads(p.stdout)

rc,data=run(ROOT)
assert rc==0 and data['ok'] is True, data
assert data['schemaContract']=='phase16.2-v3', data
assert data['violations']==[], data
assert data['stats']=={'apps':79,'featured':23,'appletCapable':21,'supported':4,'experimental':17,'defaultEnabled':0,'categories':14}

# Structured diagnostic: app + field + expected/actual must survive a negative case.
with tempfile.TemporaryDirectory() as td:
    t=Path(td); shutil.copytree(ROOT/'apps',t/'apps'); shutil.copytree(ROOT/'config',t/'config')
    p=t/'apps/whatsapp.conf'
    p.write_text(p.read_text().replace('APPLET_CAPABILITIES="notifications;badge;preview;"','APPLET_CAPABILITIES="notifications;video_crop;"'))
    rc,data=run(t)
    assert rc==1 and data['ok'] is False
    hit=next(v for v in data['violations'] if v['code']=='adapter_capability_mismatch')
    assert hit['app']=='whatsapp' and hit['field']=='APPLET_CAPABILITIES'
    assert 'expected' in hit and 'actual' in hit

pack=(ROOT/'packaging/make-runtime-tarball.sh').read_text()
assert 'validate_definitions.py' in pack and 'validate_catalog.py' in pack
repair=(ROOT/'repair.sh').read_text()
assert 'catalog-contract-last.json' in repair and 'validate_definitions.py' in repair
print('PASS: Phase16.2 contract2 structured diagnostics + packaging/repair gates')
