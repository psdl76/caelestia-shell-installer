# Phase 15.3e.1 fix1 — MPRIS runtime import fix

Fixes the runtime `NameError: name 'shutil' is not defined` in
`media_status_for_app()` by importing Python's standard-library `shutil`
module. No MPRIS matching or renderer behavior is changed.

Validation performed:
- `python -m py_compile bin/caelestia-webapps`
- `tests/test_phase15_3e1_mpris.py`
- `tests/test_status_protocol_15_3d1.py`
- direct `status-feed youtube` with a fake `playerctl` MPRIS source, yielding
  `available: true`, metadata, artwork URL, playing state and progress.
