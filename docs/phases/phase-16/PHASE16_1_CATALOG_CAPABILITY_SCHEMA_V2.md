# Phase 16.1 — Core Catalog + Applet Capability Schema v2

Status: **STATIC ACCEPTANCE ONLY — live Manager review pending**

## Scope

- Expanded the built-in catalog from 13 to **79 WebApps**.
- Expanded categories to **14**:
  AI, Messaging, Google, Microsoft, Proton, Productivity, Social, Video, Music,
  Development, Design, Cloud, Shopping, Travel.
- Added Proton as a first-class provider category.
- App definitions now author one final applet model:
  `APPLET_AVAILABLE`, `APPLET_DEFAULT_ENABLED`, `APPLET_ADAPTER`,
  `APPLET_SUPPORT`, `APPLET_CAPABILITIES`, `APPLET_MATCH_HOSTS`.
- `STATUS_INTEGRATION_*` is no longer authored by built-ins.
  `statusIntegration` remains a generated compatibility mirror for Phase 15 consumers.
- All applets default to disabled.
- Support states separate conceptual availability from live-tested support.
- Existing streaming Hyprland workspace/tag semantics are preserved for both Video
  and Music categories.
- Existing package-owned vs user-owned definition architecture is unchanged.

## Applet adapters

- `none`
- `notifications`
- `media`
- `mail`
- `calendar`

## Supported today

- WhatsApp: notifications / badge / preview
- Google Messages: notifications / badge / preview
- YouTube: media / controls / live preview / video crop / pin
- YouTube Music: media / controls / artwork

Everything else with an applet is marked `experimental`.

## Compatibility

Catalog JSON remains schemaVersion 2 during Phase 16.1 to avoid breaking the
accepted Manager/CLI/plugin consumers. A new `applet` object is added while the
legacy `statusIntegration` object is generated from the new source-of-truth fields.
