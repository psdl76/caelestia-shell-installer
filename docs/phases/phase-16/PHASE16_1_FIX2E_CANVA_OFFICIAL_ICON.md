# Phase 16.1-fix2e – Canva official icon fallback

Canva is not currently available in the Dashboard Icons catalog. The previous fix2d Simple Icons fallback did not resolve on the live system.

This patch replaces that fallback with Canva's own 192x192 site/app icon:

`https://static.canva.com/domain-assets/canva/static/images/android-192x192-2.png`

The existing resolver downloads it once, validates it as PNG, stores it in the local `store-icons-v6` cache, and the manager then uses only the local file. No generic globe is cached.

Expected live log:

```text
[OK        ] canva                  android-192x192-2           curated-external
SUMMARY total=79 resolved=79 unresolved=0
```
