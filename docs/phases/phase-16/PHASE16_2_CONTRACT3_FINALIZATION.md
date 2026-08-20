# Phase 16.2 contract3 — Finalization / Freeze Candidate

## Status

Freeze candidate for Phase 16.2.

## Changes

- Schema contract advanced to `phase16.2-v3`.
- Formal contract documented in `PHASE16_2_SCHEMA_CONTRACT_FINAL.md`.
- Interactive `caelestia-webapps validate-catalog` now prints a compact human-readable report.
- `--json` forces the stable machine/API envelope.
- Non-TTY invocation without flags remains JSON for scripting compatibility.
- `--human` forces the readable report.
- Final negative-test matrix covers adapter/capability mismatch, default-enabled applets, primary-category drift, and unsupported icon providers.
- Existing packaging and repair gates remain active.

## Accepted catalog invariants

- 79 apps
- 14 categories
- 23 featured
- 21 applet-capable
- 4 supported
- 17 experimental
- 0 default-enabled
- 79 explicit icon mappings

## Validation

- `tests/test_phase16_2_contract2.py`: PASS
- `tests/test_phase16_2_contract3.py`: PASS
- human CLI validation: PASS
- JSON CLI validation: PASS
- shell syntax checks: PASS
- runtime packaging gate: PASS
