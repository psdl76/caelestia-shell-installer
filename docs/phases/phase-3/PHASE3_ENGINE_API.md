# Phase 3 — `engine-api-01`

This checkpoint adds a stable machine-facing CLI/JSON boundary in front of the
existing UI-independent WebApps engine.

## Contract

Executable: `bin/caelestia-webapps`

Commands:

- `list`
- `status <app-id>`
- `launch <app-id>`
- `setup <app-id>`
- `install <app-id>`
- `repair <app-id>`
- `uninstall <app-id>`
- `refresh`

All command results are JSON envelopes with `apiVersion: 1` and `ok`.
The CLI delegates mutations to the existing tested engine scripts. It does not
reimplement installation, repair, removal, Firefox profile creation, Hyprland
rules or duplicate-window handling.

## Exit codes

- `0`: success
- `2`: invalid invocation
- `10`: unknown app
- `11`: app not installed for launch/setup
- `12`: generated launcher missing/not executable
- `20`: catalog generation/schema error
- `30`: delegated engine action or process start failed

## New architecture rules discovered during Phase 3

1. **stdout is an API channel.** CLI commands print JSON only; verbose engine
   output is captured by the facade and remains in existing engine logs.
2. **Launch is asynchronous.** The CLI only accepts/spawns the generated
   launcher and returns immediately. Duplicate protection remains entirely in
   the generated launcher.
3. **Repair must remain capable of fixing partial state.** The CLI therefore
   does not reject repair merely because `installed.conf` is absent; the
   existing repair engine remains authoritative.
4. **Catalog is the read model; engine scripts are the write model.** The CLI
   may enrich status with filesystem health checks, but it must not reproduce
   install/uninstall business rules.
5. **API version and catalog schema version are independent.** API v1 can
   continue to wrap a future catalog schema v2.
