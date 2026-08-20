# Documentation map

Start with the repository root `AGENTS.md` and `README.md`.

## Structure

- `phases/` contains project phase records grouped by phase number.
- `contracts/` contains cross-cutting architecture, lifecycle, schema and manager contracts.
- `history/pocs/` contains native drawer prototypes kept only for historical context.
- `history/manager/` contains older manager evolution notes.
- `history/runtime/` contains older Firefox/runtime and Caelestia motion notes.
- `releases/` contains release notes and publication boundaries.

## Current reading order for Phase 16.8

1. `../AGENTS.md`
2. `phases/phase-16/PHASE16_6_FIX1_MANAGER_MORE_ACTIONS.md`
3. `phases/phase-16/PHASE16_7_REPAIR_UPGRADE_MIGRATION.md`
4. `phases/phase-16/PHASE16_8_END_TO_END.md`
5. relevant files under `contracts/`

The later abandoned Phase 16.6 UI experiments are intentionally not part of this workspace baseline; the accepted visual starting point remains fix1.

## Current reading order for Phase 17

1. `../AGENTS.md`
2. `phases/phase-16/PHASE16_8_END_TO_END.md`
3. `phases/phase-17/PHASE17_1_MANAGER_NEXUS_LAYOUT.md`
4. `phases/phase-17/PHASE17_2_MANAGER_EMBEDDED_PAGES.md`
5. `phases/phase-17/PHASE17_3_NEXUS_MOTION_GROUPING.md`
6. `phases/phase-17/PHASE17_4_SUBPAGE_CONSISTENCY.md`
7. `phases/phase-17/PHASE17_5_WEBAPP_INFO_NAVIGATION.md`
8. `phases/phase-17/PHASE17_6_ABOUT_PAGE.md`
9. `phases/phase-17/PHASE17_7_VISUAL_ACCEPTANCE_CLOSING_GATE.md`

Phase 17 changes only the Manager's visual/layout contract. Phase 16.8 remains
the frozen backend, runtime and packaged-lifecycle baseline. Phase 17.7 is the
accepted and frozen Manager baseline.

## Current reading order for Phase 18

1. `../AGENTS.md`
2. `phases/phase-17/PHASE17_7_VISUAL_ACCEPTANCE_CLOSING_GATE.md`
3. `phases/phase-18/PHASE18_1_MANAGER_LOCALIZATION.md`
4. `phases/phase-18/PHASE18_2_RELOAD_FREE_HYPRLAND.md`
5. `phases/phase-19/PHASE19_AUR_COMMUNITY_LAUNCH.md`

Phase 18.1 adds German/English presentation without changing the frozen Phase
17.7 layout or Phase 16.8 lifecycle contracts. Both language modes are live
accepted and Phase 18.1 is frozen. Phase 18.2 prevents full monitor reloads for
app lifecycle changes on current Hyprland Lua configurations and is also live
accepted and frozen.

Phase 19 contains presentation, AUR and community-launch work only. Its AUR
candidate is locally verified, but publication remains blocked while new AUR
account registration is unavailable.

## Current release

- `releases/RELEASE_0.4.0.md` — local/private 0.4.0 release
- `releases/RELEASE_0.4.1.md` — localized, locally verified 0.4.1 release
- `releases/COMMUNITY_LAUNCH_0.4.1.md` — copy-ready community launch kit
