# Phase 15.3b — Runtime Status Protocol + Generic Renderer

Status: **implementation candidate; requires live Caelestia smoke test**.

## Goal

Keep app-specific data acquisition outside QML. The plugin consumes one normalized
status protocol and renders status generically. Real adapters are deliberately not
implemented in this phase.

```text
app-specific source -> adapter -> normalized status-feed -> generic QML renderer
```

## CLI contract

`caelestia-webapps status-feed` returns all declared non-`none` integrations.
`caelestia-webapps status-feed <app-id>` returns one normalized envelope.

Protocol v1 envelope:

```json
{
  "protocolVersion": 1,
  "appId": "whatsapp",
  "kind": "notification",
  "available": true,
  "stale": false,
  "updatedAt": 1723954210,
  "capabilities": ["badge", "preview"],
  "state": {
    "count": 3,
    "title": "Peter",
    "text": "Kommst du heute noch?"
  }
}
```

Media uses the same envelope:

```json
{
  "protocolVersion": 1,
  "appId": "youtube-music",
  "kind": "media",
  "available": true,
  "stale": false,
  "updatedAt": 1723954210,
  "capabilities": ["now_playing", "playback_controls"],
  "state": {
    "title": "Song",
    "subtitle": "Artist",
    "artwork": "",
    "playing": true,
    "progress": 0.42
  }
}
```

Unavailable adapters keep a stable shape with `available: false` and an empty
`state` object. This means the renderer does not need app-specific fallback logic.

## Generic renderer

`WebAppsPopout.qml` now requests `status-feed` after loading the catalog. It maps
statuses by `appId` and only understands protocol concepts:

- `notification`: badge + optional title/text preview
- `media`: title/subtitle + playing/paused indicator
- unavailable/unknown: existing compact launcher row

There is no WhatsApp-, Gmail-, ChatGPT- or YouTube-specific parser in QML.

## Demo fixtures

Until Phase 15.3c adds real adapters, renderer testing is opt-in through the CLI
environment:

```bash
CAELESTIA_WEBAPPS_STATUS_DEMO=notification
CAELESTIA_WEBAPPS_STATUS_DEMO_APP=whatsapp
```

or:

```bash
CAELESTIA_WEBAPPS_STATUS_DEMO=media
CAELESTIA_WEBAPPS_STATUS_DEMO_APP=whatsapp
```

The demo changes only normalized runtime status; it does not mutate catalog data.

## Next step

After live renderer acceptance, Phase 15.3c replaces the fixture source with the
first real adapters while keeping this protocol and QML boundary unchanged.
