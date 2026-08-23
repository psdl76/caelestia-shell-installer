# AGENTS.md — Caelestia WebApps

This repository is the working source of truth for the Caelestia WebApps project.
Read this file before changing code.

## Project environment

- Arch Linux / CachyOS-compatible userspace
- Hyprland
- Caelestia Shell / Quickshell
- Firefox
- zsh
- Manager: standalone QML/Quickshell UI
- Main stable CLI: `bin/caelestia-webapps`

## Current project status

The baseline represented by this workspace is:

- Phase 16.1 — catalog/schema v2: LIVE ACCEPTED / FROZEN
- Phase 16.2 — validator/schema contract: LIVE ACCEPTED / FROZEN
- Phase 16.3 — applet registry/runtime metadata: LIVE ACCEPTED / FROZEN
- Phase 16.4 — installer/uninstaller metadata coupling: LIVE ACCEPTED / FROZEN
- Phase 16.5 — optional applet activation: LIVE ACCEPTED / FROZEN
- Phase 16.6 — capability settings: functionally accepted; UI baseline intentionally reset to `phase16-6-fix1-manager-more-actions`
- Phase 16.7 — repair/upgrade/migration: LIVE ACCEPTED / FROZEN
- Phase 16.8 — end-to-end closing gate: ACCEPTED / FROZEN
- Phase 17.1 — Manager Caelestia Nexus layout: LIVE ACCEPTED / FROZEN
- Phase 17.2 — embedded animated Manager detail pages: LIVE ACCEPTED / FROZEN
- Phase 17.3 — Nexus motion and connected action grouping: LIVE ACCEPTED / FROZEN
- Phase 17.4 — consistent Nexus Manager subpages: LIVE ACCEPTED / FROZEN
- Phase 17.5 — Nexus AllApps/WebApp-Info navigation: LIVE ACCEPTED / FROZEN
- Phase 17.6 — Nexus-style About page: LIVE ACCEPTED / FROZEN
- Phase 17.7 — Manager visual acceptance and closing gate: ACCEPTED / FROZEN
- Release 0.4.0 — local/private package release: RELEASED / TAGGED
- Phase 18.1 — German/English Manager localization: LIVE ACCEPTED / FROZEN
- Phase 18.2 — reload-free Hyprland Lua integration: LIVE ACCEPTED / FROZEN
- Release 0.4.1 — localized package release: PUBLIC / LIVE ACCEPTED
- Phase 19 — AUR and community launch: AUR CANDIDATE VERIFIED / ACCOUNT REGISTRATION BLOCKED
- Phase 20.1 — product branding and animated About hero: LIVE ACCEPTED / FROZEN
- Release 0.4.2 — branded package release: PUBLIC / LIVE ACCEPTED
- Release 0.4.3 — stability and packaging hardening: PUBLIC / LIVE ACCEPTED

Do not reopen a frozen phase unless a real regression is demonstrated by a failing contract, failing regression test, or reproducible live bug.

## Critical UI baseline rule

The frozen Manager UI baseline is **Phase 17.7 — Manager visual acceptance and closing gate**.

Phase 17 explicitly supersedes its top-level toolbar/catalog layout with a
Caelestia-Nexus-inspired sidebar and main screen. The Phase 16 More Actions
boundary and all CLI/runtime behavior remain frozen.

Do not reintroduce the abandoned UI experiments from later Phase 16.6 fixes (surface-alignment / unified-design / connected-row / motion-controls / select-popouts / SplitButton experiments). Phase 17 is a new visual contract based specifically on the live Caelestia Nexus settings UI, not a revival of those patches.

Do not reopen the Phase 17 visual baseline without a reproducible live UI bug or
a failing regression contract.

## Architecture rules

1. QML talks to the application through the stable CLI `bin/caelestia-webapps`.
2. From QML, execute commands using argument lists. Do not construct shell command strings.
3. Third-party plugin code must not depend on private Caelestia APIs.
4. Do not add `import qs.*` or private `Caelestia.*` dependencies to plugin/standalone code.
5. Prefer documented public Qt / Quickshell APIs.
6. `applet-registry.json` is the runtime metadata source for applet/runtime integration.
7. Catalog compatibility fields must not silently become a second runtime metadata source.
8. Persistent applet activation and capability settings are user state. Preserve valid user choices across repair/upgrade.
9. Successful uninstall of an app must reset only that app's activation override to `false`; capability settings are preserved unless a documented contract says otherwise.
10. Repair/upgrade state migration must be idempotent and use atomic writes/backups as implemented in Phase 16.7.

## Phase 16.8 closing notes

Phase 16.8 exposed two integration regressions that are fixed in this workspace and must remain covered by regression tests:

- successful uninstall must reset the applet activation override for the uninstalled app
- `repair.sh` / `upgrade.sh --preflight` must handle the migration tool's `NEEDS-MIGRATION` exit path without the global `ERR` trap aborting self-heal

Relevant regression tests:

- `tests/test_phase16_8_uninstall_applet_reset.sh`
- `tests/test_phase16_8_installed_upgrade_migration.sh`

Do not remove or weaken these tests just to make another change pass.

## Development workflow

Before editing:

1. Read this file.
2. Read `README.md`.
3. Read the relevant phase/contract documents under `docs/`.
4. Locate the implementation and existing tests.
5. Reproduce the problem before modifying code when practical.

When editing:

1. Make the smallest change that satisfies the existing contract.
2. Do not broaden scope without explicit instruction.
3. Keep frozen behavior unchanged.
4. Add a focused regression test for every confirmed bug.
5. Never silently weaken, skip, or delete a regression test to make a change pass.

After editing:

1. Run the focused regression test.
2. Run the relevant Phase 16 tests.
3. Run shell syntax tests when shell files changed.
4. Run packaging/end-to-end tests when lifecycle/install/repair/uninstall code changed.
5. Report exactly what was run and what was not run.

## Test guidance

Useful tests/gates include:

```bash
python3 tests/test_phase16_2_contract2.py
python3 tests/test_phase16_2_contract3.py
python3 tests/test_phase16_2_schema_contract.py
python3 tests/test_phase16_3_registry1.py
python3 tests/test_phase16_3_registry2.py
python3 tests/test_phase16_3_registry3.py
python3 tests/test_phase16_5_applet_activation.py
python3 tests/test_phase16_6_capability_settings.py
python3 tests/test_phase16_6_fix1_manager_more_actions.py
python3 tests/test_phase16_7_repair_upgrade_migration.py
bash tests/test_phase16_8_uninstall_applet_reset.sh
bash tests/test_phase16_8_installed_upgrade_migration.sh
bash tests/test_shell_syntax.sh
bash tests/run_phase13_gate.sh
bash tests/run_phase17_7_closing_gate.sh
bash tests/run_phase18_1_gate.sh
bash tests/run_phase19_aur_gate.sh
python3 tests/test_phase20_1_product_branding.py
```

Some tests require an isolated HOME/XDG environment. If a test unexpectedly touches the developer's real environment, stop and inspect the test setup instead of adapting product behavior to the host machine.

Do not claim a graphical Quickshell/Hyprland test passed unless it actually ran in a graphical session.

## Real application validation

Codex may run commands and inspect logs on the local Arch workstation, but it must be conservative with the user's real installation.

Safe by default:

- read source files
- run repository tests
- inspect `git diff` / `git status`
- run CLI read-only/status commands
- inspect Quickshell logs
- use temporary HOME/XDG directories for destructive tests

Ask before:

- modifying the user's real `~/.local` installation
- deleting/reinstalling a real WebApp
- changing Hyprland/Caelestia configuration
- resetting real persistent applet state
- running a destructive command outside the repository/test sandbox

## Packaging rules

Release/test archives must contain exactly one top-level project directory.

Do not create tarballs whose members are rooted at `./`.

Before handing off an archive, verify every member begins with the exact intended top-level directory and exclude caches such as `__pycache__`, `.pytest_cache`, `.git`, build artifacts, and editor metadata unless explicitly required.

## Git rules for autonomous work

- Work on a branch for non-trivial changes.
- Keep commits small and descriptive.
- Do not rewrite published history unless explicitly requested.
- Never commit secrets, tokens, browser profiles, runtime state, logs containing private data, or generated caches.
- Prefer showing the user `git diff` before a broad refactor.

## Documentation layout

- `docs/phases/` — phase history and accepted contracts
- `docs/contracts/` — cross-cutting technical contracts
- `docs/history/pocs/` — historical prototypes/POCs
- `docs/history/manager/` — historical Manager evolution notes
- `docs/history/runtime/` — historical runtime/motion notes

Historical documents explain why the current implementation exists. They are not permission to resurrect superseded behavior.

## Goal

**Phases 16.8, 17.7, 18.1, 18.2 and 20.1 are accepted and frozen. Releases
0.4.1, 0.4.2 and 0.4.3 are public accepted releases.** Preserve the
proven packaged lifecycle, the accepted localized Nexus-style Manager baseline
and the standalone boundary from private Caelestia QML dependencies. The
canonical repository is `https://github.com/psdl76/caelestia-shell-installer`
and the redistribution license is GPL-3.0-only.
