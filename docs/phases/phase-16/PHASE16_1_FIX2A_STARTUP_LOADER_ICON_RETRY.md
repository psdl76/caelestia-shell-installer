# Phase 16.1-fix2a — Caelestia startup loader + deterministic icon retry

## Startup UX

- `manager.sh` now starts Quickshell immediately.
- A compact Caelestia-style startup window is shown while preflight runs.
- The loader uses the existing public Caelestia scheme bridge (`scheme.json` -> local theme JSON).
- It deliberately does not import private `qs.*` or private Caelestia QML APIs.
- Real startup stages are streamed from `scripts/manager_preflight.sh` via Quickshell `SplitParser`:
  1. Caelestia theme
  2. local WebApp icons
  3. catalog refresh
  4. Manager ready
- Icon progress shows the real app count and current App ID.

## Icon pipeline repair

The fix2 cache could become permanently poisoned by the generic SVG fallback:

1. Dashboard download failed once.
2. Generic SVG was copied to the store cache.
3. Every later launch considered that generic SVG a valid cached store icon.
4. The real Dashboard icon was never retried.

This explains cases such as Gemini even though Dashboard Icons contains `google-gemini`.

fix2a changes this:

- cache bumped from `store-icons-v4` to `store-icons-v5`;
- Dashboard Icons acquisition is derived from explicit `ICON_ID` only;
- primary acquisition URL is `raw.githubusercontent.com/homarr-labs/dashboard-icons/main/...`;
- generic fallback is **never written to the store cache**;
- unresolved icons use the bundled local fallback for that launch and are retried later;
- built-in Manager entries never load their configured remote `iconUrl` at runtime;
- removed the Gemini-specific PNG preference from catalog generation.

Gemini remains explicitly mapped as:

```bash
ICON_PROVIDER="dashboard-icons"
ICON_ID="google-gemini"
```
