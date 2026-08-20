# Caelestia WebApps Manager — v0.3.17

Dieser Stand priorisiert für den Store die normalen Dashboard-Icons.

- `ICON_URL` wird zuerst in `~/.cache/caelestia-webapps/store-icons-v2/` gecacht.
- Bei jsDelivr-Problemen wird dieselbe Dashboard-Icons-Datei über GitHub Raw versucht.
- Paketlokale Streaming-SVGs dienen nur noch als Offline-/Notfall-Fallback.
- Gemini verwendet `google-gemini.svg` und profitiert ebenfalls von Retry/Fallback.
- Die eigentliche Installations-/Hyprland-/Firefox-/Caelestia-Logik bleibt unverändert im Backend.
