# Phase 15.3c.2 — Google Messages generic per-app instance

Status: candidate for live test.

This phase adds Google Messages as a second thin instance of the generic per-app status UI.
No Google-Messages-specific renderer is introduced.

## Entry points

- `webapp-whatsapp` -> existing generic WhatsApp instance
- `webapp-google-messages` -> new generic Google Messages instance
- `webapps` -> central launcher/manager entry

## Styling rule

Per-app bar icons are rendered as monochrome, theme-aware silhouettes using `layer.effect: MultiEffect`.
Original colourful brand icons remain in popouts and the WebApps manager.

## Expected demo

With:

```bash
CAELESTIA_WEBAPPS_STATUS_DEMO=notification
CAELESTIA_WEBAPPS_STATUS_DEMO_APP=google-messages
```

Google Messages should show the demo badge/preview in its own bar entry/popout. WhatsApp remains a normal per-app entry without a demo badge for that run.
