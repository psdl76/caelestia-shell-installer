from __future__ import annotations
import json, os, shutil, subprocess, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VAL = ROOT / 'scripts/validate_definitions.py'
CLI = ROOT / 'bin/caelestia-webapps'

def run_validator(root: Path):
    p = subprocess.run(['python3', str(VAL), str(root)], text=True, capture_output=True)
    return p.returncode, json.loads(p.stdout)

def mutated(app: str, old: str, new: str):
    td = tempfile.TemporaryDirectory()
    t = Path(td.name)
    shutil.copytree(ROOT/'apps', t/'apps')
    shutil.copytree(ROOT/'config', t/'config')
    p = t/'apps'/f'{app}.conf'
    text = p.read_text()
    assert old in text, (app, old)
    p.write_text(text.replace(old, new, 1))
    return td, t

rc, report = run_validator(ROOT)
assert rc == 0 and report['ok'] is True, report
assert report['schemaContract'] == 'phase16.2-v3'
assert report['violations'] == []

# Final negative matrix: each class of cross-field failure must be rejected.
cases = [
    ('whatsapp', 'APPLET_CAPABILITIES="notifications;badge;preview;"', 'APPLET_CAPABILITIES="notifications;video_crop;"', 'adapter_capability_mismatch'),
    ('youtube', 'APPLET_DEFAULT_ENABLED="false"', 'APPLET_DEFAULT_ENABLED="true"', 'applet_default_enabled'),
    ('teams', 'APP_CATALOG_CATEGORIES_LIST="messaging;microsoft;"', 'APP_CATALOG_CATEGORIES_LIST="microsoft;"', 'primary_category_missing'),
    ('chatgpt', 'ICON_PROVIDER="dashboard-icons"', 'ICON_PROVIDER="made-up-provider"', 'icon_provider_unsupported'),
]
for app, old, new, code in cases:
    td, root = mutated(app, old, new)
    try:
        rc, data = run_validator(root)
        assert rc == 1 and data['ok'] is False, (app, data)
        assert any(v.get('code') == code for v in data['violations']), (app, code, data)
    finally:
        td.cleanup()

# CLI: explicit --json keeps the stable JSON envelope.
p = subprocess.run([str(CLI), 'validate-catalog', '--json'], cwd=ROOT, text=True, capture_output=True)
assert p.returncode == 0, p.stderr
payload = json.loads(p.stdout)
assert payload['ok'] is True and payload['command'] == 'validate-catalog'
assert payload['data']['schemaContract'] == 'phase16.2-v3'
assert payload['data']['violations'] == 0

# --human is deterministic even under captured stdout.
p = subprocess.run([str(CLI), 'validate-catalog', '--human'], cwd=ROOT, text=True, capture_output=True)
assert p.returncode == 0, p.stderr
assert 'Caelestia WebApps · Catalog Contract' in p.stdout
assert 'PASS · Catalog schema contract valid' in p.stdout
assert 'Icon-Mappings' in p.stdout

# Piped/no-TTY compatibility: no flag remains JSON.
p = subprocess.run([str(CLI), 'validate-catalog'], cwd=ROOT, text=True, capture_output=True)
assert p.returncode == 0
json.loads(p.stdout)

formal = (ROOT/'PHASE16_2_SCHEMA_CONTRACT_FINAL.md').read_text()
assert 'phase16.2-v3' in formal and 'Frozen Phase 16.1 invariants' in formal
print('PASS: Phase16.2 contract3 final schema + human/JSON CLI + negative matrix')
