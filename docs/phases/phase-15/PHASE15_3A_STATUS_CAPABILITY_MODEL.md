# Phase 15.3a — Status Adapter / Capability Data Model

Status: **implementation candidate; data-model contract ready for live integration testing**.

## Architecture decision

WebApps are presets. The Caelestia WebApps popout is one generic renderer/launcher.
Persistent status is supplied separately by app-specific adapters and normalized
before it reaches QML.

```text
WebApp definition
    -> status adapter (app-specific input)
    -> normalized status protocol
    -> generic Caelestia renderer
```

The renderer must not contain WhatsApp-, Gmail-, ChatGPT- or YouTube-Music-specific
parsing logic.

## Catalog metadata

Each catalog app now exposes, additively to catalog schema v2:

```json
{
  "provider": "google",
  "tags": ["communication", "messaging", "popular"],
  "featured": true,
  "statusIntegration": {
    "type": "notification",
    "recommended": true,
    "capabilities": ["badge", "preview"]
  }
}
```

`appletVisible` remains independent: it only controls visibility in the central
WebApps popout.

## Status integration types v1

- `none`
- `notification`
- `activity`
- `media`
- `calendar`
- `tasks`
- `transfer`
- `deployment`

Capabilities are deliberately composable. Initial examples include `badge`,
`preview`, `status_text`, `now_playing`, and `playback_controls`.

## Current built-in declarations

- WhatsApp / Google Messages: `notification` + `badge`, `preview`
- ChatGPT / Gemini / Claude: `activity` + `status_text` (declared potential;
  not yet an implemented adapter)
- YouTube: `media` + `now_playing`, `playback_controls` (declared potential)
- passive streaming presets: `none`

No live adapter is implemented in Phase 15.3a. This phase defines only the
stable metadata boundary and keeps the existing launcher/popout behavior intact.

## Next step — Phase 15.3b

Define the normalized runtime status protocol, then implement two deliberately
different adapters against the same generic renderer:

1. notification family: WhatsApp / Google Messages
2. media family: YouTube Music (or another MPRIS-capable web media target)

This proves the abstraction before expanding to mail, calendar, tasks, activity,
transfer or deployment.
