#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATOR = ROOT / 'scripts/migrate_runtime_state.py'
REPAIR = (ROOT / 'repair.sh').read_text(encoding='utf-8')
UPGRADE = (ROOT / 'upgrade.sh').read_text(encoding='utf-8')

assert 'STATE_MIGRATOR="$ROOT_DIR/scripts/migrate_runtime_state.py"' in REPAIR
assert '--state-root "$STATE_ROOT" --check --json' in REPAIR
assert 'step "Applet Runtime-State migrieren"' in REPAIR
assert 'exec "$ROOT_DIR/repair.sh" "$@"' in UPGRADE

with tempfile.TemporaryDirectory() as td:
    state = Path(td) / 'state'
    state.mkdir()

    # Legacy activation flat-map + mixed bool spellings.
    old_applets = b'{"youtube":"on","whatsapp":0,"bad":"maybe"}\n'
    (state / 'applets.json').write_bytes(old_applets)

    # Partially malformed settings; valid choices must survive.
    old_settings = {
        'schemaVersion': 0,
        'apps': {
            'youtube': {'live_preview': False, 'pin': 'off', 'bad': 'wat'},
            'whatsapp': {'badge': True},
            'broken': 'not-a-map',
        },
    }
    (state / 'applet-settings.json').write_text(json.dumps(old_settings), encoding='utf-8')

    check = subprocess.run(
        ['python3', str(MIGRATOR), '--state-root', str(state), '--check', '--json'],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    assert check.returncode == 10, check.stderr
    report = json.loads(check.stdout)
    assert report['changed'] is True
    # Check mode must not mutate.
    assert (state / 'applets.json').read_bytes() == old_applets

    run = subprocess.run(
        ['python3', str(MIGRATOR), '--state-root', str(state), '--json'],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    assert run.returncode == 0, run.stderr
    migrated = json.loads(run.stdout)
    assert migrated['changed'] is True

    applets = json.loads((state / 'applets.json').read_text())
    assert applets == {
        'schemaVersion': 1,
        'enabled': {'whatsapp': False, 'youtube': True},
    }

    settings = json.loads((state / 'applet-settings.json').read_text())
    assert settings == {
        'schemaVersion': 1,
        'apps': {
            'whatsapp': {'badge': True},
            'youtube': {'live_preview': False, 'pin': False},
        },
    }

    backups = sorted((state / 'migration-backups').glob('*.bak'))
    assert len(backups) == 2
    expected_digest = hashlib.sha256(old_applets).hexdigest()[:16]
    assert any(p.name == f'applets.json.{expected_digest}.bak' for p in backups)

    before = {p: p.read_bytes() for p in state.rglob('*') if p.is_file()}
    second = subprocess.run(
        ['python3', str(MIGRATOR), '--state-root', str(state), '--json'],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    assert second.returncode == 0, second.stderr
    assert json.loads(second.stdout)['changed'] is False
    after = {p: p.read_bytes() for p in state.rglob('*') if p.is_file()}
    assert before == after

# Invalid JSON must be backed up and replaced by safe canonical empty state.
with tempfile.TemporaryDirectory() as td:
    state = Path(td) / 'state'
    state.mkdir()
    raw = b'{ definitely-not-json'
    (state / 'applets.json').write_bytes(raw)
    proc = subprocess.run(
        ['python3', str(MIGRATOR), '--state-root', str(state), '--json'],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    assert proc.returncode == 0
    assert json.loads((state / 'applets.json').read_text()) == {'schemaVersion': 1, 'enabled': {}}
    backups = list((state / 'migration-backups').glob('applets.json.*.bak'))
    assert len(backups) == 1 and backups[0].read_bytes() == raw

print('PASS: Phase16.7 repair/upgrade runtime-state migration is preserving, atomic and idempotent')
