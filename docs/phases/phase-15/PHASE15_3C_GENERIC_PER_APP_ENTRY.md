# Phase 15.3c — Generic per-app bar entry (PoC1)

Goal: apps with meaningful status can have their own Caelestia bar entry/popout while sharing generic QML renderers.

PoC app: WhatsApp.

Architecture:
- `GenericStatusBarEntry.qml` renders app icon + generic badge/status dot.
- `GenericStatusPopout.qml` renders normalized `status-feed` kinds.
- `WhatsAppBarEntry.qml` and `WhatsAppPopout.qml` are thin declarative wrappers only (`appId: "whatsapp"`).
- Manifest exposes `webapp-whatsapp` as `bar-entry` + matching `bar-popout`.
- Existing central `webapps` entry remains unchanged.
- PATH resolution preserves caller precedence and appends `~/.local/bin` only as fallback.

This is a PoC. Do not freeze until live-tested on the feature branch.
