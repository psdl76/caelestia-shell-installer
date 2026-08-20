# Phase 15.3d.2c — Notification Images / Avatars

- Parses the freedesktop `image-data` / `image_data` Notify hint.
- Converts 8-bit RGB/RGBA image-data to PNG using Python stdlib only.
- Stores images under `$XDG_CACHE_HOME/caelestia-webapps/notification-images/`.
- Exposes the cached PNG through Protocol v1 `items[].image`.
- GenericStatusPopout renders the image as a circular avatar; no app-specific QML.
- Cached images are removed when the matching notification closes or is replaced.
