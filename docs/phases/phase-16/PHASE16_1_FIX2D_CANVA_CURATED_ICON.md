# Phase 16.1-fix2d – Canva curated icon fallback

## Problem

The native Dashboard Icons tree does not currently contain a `canva` asset, so the explicit
Dashboard mapping could never resolve and the manager displayed the generic globe fallback.

## Fix

- Keep Dashboard Icons as the primary provider for the catalog overall.
- Canva is an explicit exception using the curated Simple Icons `canva` asset.
- The asset is downloaded once during the existing icon preparation phase and stored in the
  local `store-icons-v6` cache.
- Runtime remains local-only.
- No generic globe is cached as a successful result.

## Expected icon-pipeline result

```text
[OK        ] canva                  canva                        curated-external
SUMMARY total=79 resolved=79 unresolved=0
```
