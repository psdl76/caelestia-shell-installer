# Caelestia WebApps Manager — v0.3.18

Korrekturen am Store-Icon-Resolver:

- Paramount+ und WOW verwenden direkt ihre gebündelten lokalen SVGs; für diese beiden
  Definitionen wird keine nicht vorhandene Dashboard-Icons-URL mehr abgefragt.
- Gemini behält `google-gemini.svg` als Dashboard-Icons-Quelle.
- Optionale CDN/GitHub-Fallback-Downloads laufen still. Ein fehlgeschlagenes Icon darf
  die Manager-Konsole nicht mit `curl: (22)` verunreinigen.
- Das bestehende lokale Fallback-Verhalten bleibt erhalten.
- Keine Install-/Repair-/Uninstall-/Hyprland-/Firefox-Logik wurde verändert.
