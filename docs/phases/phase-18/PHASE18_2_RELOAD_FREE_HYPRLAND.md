# Phase 18.2 — Reload-free Hyprland Lua Integration

Status: **LIVE ACCEPTED / FROZEN**

## Regression

Installing or uninstalling a WebApp caused a brief black screen on the real
Hyprland 0.56.2 Lua session. The Hyprland log proved that a full configuration
reload modeset `DP-3` first to 59.95 Hz and then back to 144 Hz.

The lifecycle changed an imported `rules.lua` file and also called
`hyprctl reload`. Current Lua Hyprland configurations automatically reload when
a configuration file is saved, so a WebApp rule update unnecessarily re-ran
the complete monitor configuration.

## Contract

For a running Lua configuration with the public runtime API:

1. validate all temporary Lua files before touching live files;
2. temporarily set `misc:disable_autoreload` while committing the validated
   app-owned changes, and synchronously execute Hyprland's scheduled watcher
   refresh before writing any imported file;
3. persist the same ownership-marked rules as before;
4. activate only named app-specific tag rules with `hyprctl eval`;
5. disable those named runtime rules during uninstall;
6. restore the user's previous autoreload value;
7. never call full `hyprctl reload` on the successful Lua path.

The real acceptance attempt also exposed a rollback race in the manual gate:
an imported Lua file was unlinked before its backup was copied back, allowing a
reload to observe a missing `hyprland.keybinds` module. Rollback therefore
replaces regular files atomically and never exposes a missing-file interval.

Older or non-Lua Hyprland configurations retain the existing validated reload
and `configerrors` fallback.

## Acceptance

```bash
bash tests/run_phase18_2_gate.sh
```

## Live acceptance

The corrected real 0.4.1 lifecycle ran on 2026-08-20 in the developer's
Hyprland 0.56.2 Lua session. It installed the candidate Core, created and
installed a temporary WebApp, checked its status, uninstalled and deleted it,
removed the candidate Core and restored the previous installation.

The Hyprland log contained **zero new DP-3 modesets**, `configerrors` remained
empty and all 143 keybinds remained loaded. The user confirmed that the display
stayed stable without a black frame. Evidence is retained at
`/tmp/caelestia-webapps-real-0.4.1.KD5cWc` on the validation host.

Phase 18.2 is accepted and frozen.
