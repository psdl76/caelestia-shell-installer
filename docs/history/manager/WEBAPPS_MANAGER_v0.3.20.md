# Caelestia WebApps Manager — v0.3.20

Gemini Store-Icon Fix

Der aktuelle `google-gemini.svg`-Asset wird von Qt/Quickshell auf dem Zielsystem
nicht zuverlässig dargestellt, obwohl die Datei formal ein SVG ist. Der dazugehörige
`google-gemini.png`-Asset funktioniert dagegen korrekt.

Darum gilt ausschließlich für Gemini:

1. Store-Resolver bevorzugt `google-gemini.png`.
2. Ein vorhandener alter `google-gemini.svg`-Cache wird entfernt, sobald das PNG erfolgreich gecacht wurde.
3. `generate_catalog.py` bevorzugt bei Gemini explizit die PNG-Datei, falls beide Formate vorhanden sind.
4. Alle anderen Apps behalten ihre bisherige SVG→PNG→lokal-Fallback-Logik.

Der Fix betrifft nur die Store-/Manager-Icon-Schicht. Desktop-Icons, Installer,
Firefox, Hyprland und Caelestia-Applet bleiben unverändert.
