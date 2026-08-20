# Caelestia WebApps Manager — v0.3.14

Der Manager ist bewusst **nur eine Oberfläche** über dem bestehenden Backend.

## Architektur

`catalog.json` liefert App-Metadaten und Installationsstatus. Die GUI führt für Änderungen
ausschließlich die vorhandenen Backend-Einstiegspunkte aus:

- `install.sh`
- `uninstall.sh`
- `repair.sh`
- die generierten App-/Setup-Launcher

Die QML-Oberfläche verändert weder Hyprland- noch Caelestia- noch Firefox-Konfigurationen direkt.

## UI

Die erste Version orientiert sich an Caelestias Dashboard-Vibe:

- dunkle, groß gerundete Karten
- hellblauer Akzent
- Kategorien `Alle`, `Messaging`, `AI`, `Streaming`
- Suche
- App-Icons und Installationsstatus
- primäre Aktion `Installieren` / `Öffnen`
- Kontextmenü für Setup, Repair und Uninstall
- Busy-/Fehlerstatus

## Start

```bash
./manager.sh
```

Diese erste GUI-Version ist absichtlich ein iterierbarer Prototyp. Backend und Tests bleiben
unverändert die Source of Truth.
