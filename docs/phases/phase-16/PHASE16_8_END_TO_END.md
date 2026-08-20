# Phase 16.8 — End-to-End Final Gate

## Scope

Phase 16.8 is the final integration gate for the Phase 16 line. It adds no new product feature and makes no Manager UI redesign. The baseline remains the Phase 16.6 fix1 Manager UI plus the accepted Phase 16.7 runtime-state migration path.

## Integrated contracts

The gate verifies the already frozen/accepted contracts together:

- Phase 16.2 catalog/schema contract
- Phase 16.3 applet registry and runtime metadata source
- Phase 16.4 catalog/registry lifecycle coupling and failure preservation
- Phase 16.5 optional supported-applet activation
- Phase 16.6 capability settings and Manager more-actions baseline
- Phase 16.7 repair/upgrade runtime-state migration
- installed package lifecycle and user-data preservation

## E2E regressions found and fixed

### 1. Successful uninstall did not reset applet activation

Phase 16.5 documents that a successful uninstall resets the applet activation override to `false`. The final integrated path exposed that `uninstall.sh` removed the app artifacts but left a previous `enabled: true` override behind.

The uninstall path now atomically resets only the matching activation entry after successful removal. Capability preferences in `applet-settings.json` are intentionally preserved for a later reinstall.

### 2. Repair/upgrade preflight trapped the migrator's expected exit 10

The Phase 16.7 migrator deliberately returns exit code `10` in `--check` mode when migration is required. `repair.sh --preflight` attempted to inspect that code with `set +e`, but the global `ERR` trap fired first and aborted the upgrade.

The check is now executed in an `if` condition, where the expected non-zero status can be handled safely. Exit `10` therefore triggers Self-Heal as intended; unexpected codes still fail the repair.

## Final gate

Run:

```bash
bash tests/run_phase16_8_gate.sh
bash tests/run_phase13_gate.sh
bash tests/test_shell_syntax.sh
```

No network access is required by the Phase 16.8-specific tests. Installed-package tests use isolated temporary HOME/XDG roots and stub external desktop/runtime commands where appropriate.
