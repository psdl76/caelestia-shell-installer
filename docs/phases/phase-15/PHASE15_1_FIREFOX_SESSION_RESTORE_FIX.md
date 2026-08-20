# Phase 15.1 — Firefox Session Restore Fix 01

Status: **CANDIDATE — LIVE VALIDATION REQUIRED**

## Bug

After an OS reboot, reopening a dedicated Firefox WebApp profile could show Firefox's
"Restore Session" / crash recovery UI instead of opening the configured WebApp URL.

## Fix

Dedicated WebApp profiles now explicitly set:

```js
user_pref("browser.sessionstore.resume_from_crash", false);
```

The setting is scoped only to Caelestia WebApps profiles. The user's normal Firefox
profile is not modified. Existing WebApp profiles receive the setting through the normal
repair/install path.

## Regression coverage

`tests/test_firefox_runtime.sh` now verifies both:

1. New dedicated profiles disable Firefox crash session restore.
2. `repair` migrates an existing profile where crash session restore was enabled.

## Required live test

1. Install this core candidate.
2. Repair at least ChatGPT and WhatsApp.
3. Launch both WebApps.
4. Reboot while the WebApps are open.
5. Reopen each WebApp.
6. Expected: the configured WebApp URL opens directly; no Firefox session-restore page.
