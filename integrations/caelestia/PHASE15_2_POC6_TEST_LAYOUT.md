# Phase 15.2 — PoC6 test layout

PoC6 keeps the supported `bar-entry` + `bar-popout` contract. There is no assumed private Media/Spotify attachment API. For the live layout test, place `webapps` immediately after `tray` and before `clock` in the isolated `bar.entries` array. This lets us visually compare it with the media/tray area without coupling the plugin to internal Caelestia modules.

```json
{
  "id": "tray",
  "enabled": true
},
{
  "id": "webapps",
  "enabled": true
},
{
  "id": "clock",
  "enabled": true
}
```
