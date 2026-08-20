# Phase 16.3 registry3-fix3 — Bare-host normalization

Status: TEST CANDIDATE

## Problem

`applet-registry.json` stores `matchHosts` as bare hostnames such as `youtube.com`.
The runtime host normalizer previously passed those values directly to
`urllib.parse.urlparse()`. A bare hostname is parsed as a path, so `.hostname`
was empty. BiDi therefore received an empty `matchHost` even though Firefox
returned the correct YouTube browsing context.

## Fix

`_normalise_host()` now accepts both full URLs and bare hostnames. Bare values
are parsed as scheme-relative hosts (`//youtube.com`), while normal URLs retain
the existing code path. Leading `www.` continues to be stripped.

Examples:

- `youtube.com` → `youtube.com`
- `www.youtube.com` → `youtube.com`
- `https://www.youtube.com/watch?v=...` → `youtube.com`
- `music.youtube.com` → `music.youtube.com`

No schema, registry, QML, installer/uninstaller, or BiDi protocol changes are
included in this fix.
