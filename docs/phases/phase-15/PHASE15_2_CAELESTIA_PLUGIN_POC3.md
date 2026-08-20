# Phase 15.2 — Caelestia Plugin PoC3

Status: candidate for live test; not frozen.

Changes from PoC2:

- Manifest compatibility floor corrected from `>=2.3.0` to `>=2.2.0`, matching the live `feat/plugins` shell version observed during testing.
- `WebAppsPopout.qml` now extends the environment of its `Process` objects so `$HOME/.local/bin` is available even when Quickshell was launched with a PATH that omits it.
- CLI calls remain argv-based (`["caelestia-webapps", ...]`); no shell command strings were introduced.
- Both list/launch and manager actions use the same hardened PATH.

Live behavior from PoC2 already confirmed before this candidate:

- plugin discovery / enablement
- bar-entry rendering
- bar-popout rendering
- CLI list parsing and app filtering
- ChatGPT launch focuses the existing window without spawning a duplicate
