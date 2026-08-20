# Caelestia WebApps Manager — v0.3.19

Gemini-Fix: Der Store-Icon-Resolver ist nicht mehr SVG-only.

Reihenfolge:
1. vorhandenes gecachtes SVG,
2. konfigurierte SVG-Quelle,
3. Dashboard-Icons PNG mit demselben Icon-Namen,
4. lokales gebündeltes SVG als Notfall-Fallback.

Damit kann `google-gemini.png` verwendet werden, obwohl kein nutzbares
`google-gemini.svg` vorhanden ist. QML lädt weiterhin ausschließlich lokale Dateien.

Cache: `~/.cache/caelestia-webapps/store-icons-v3/`
