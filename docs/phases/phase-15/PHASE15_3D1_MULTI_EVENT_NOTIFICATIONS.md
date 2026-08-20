# Phase 15.3d.1 — Multi-event notification protocol + generic popout

Status: candidate; live validation pending.

## Goal

Extend protocol v1 additively so notification adapters can expose multiple events
without app-specific QML. The legacy `state.title` / `state.text` fields remain
valid and mirror the newest item in the demo fixture.

## Notification state

```json
{
  "count": 5,
  "title": "Demo Kontakt",
  "text": "Das ist die neueste generische Nachrichtenvorschau.",
  "items": [
    {
      "id": "demo-1",
      "title": "Demo Kontakt",
      "text": "...",
      "timestamp": 1787033412,
      "image": "",
      "actions": []
    }
  ]
}
```

The generic per-app popout renders at most three previews and summarizes the
remaining count. The central WebApps launcher stays compact and uses only the
newest event as its one-line preview.

No real WhatsApp/Google Messages adapter is included yet.
