# Caelestia WebApps Manager — v0.3.15

Dieser Stand korrigiert die ersten Realtest-Funde des v0.3.14-Prototyps.

## Änderungen

- Nicht installierte Apps verwenden jetzt ihre lokale Paket-Iconquelle und, falls diese fehlt, `ICON_URL`.
- Installierte Apps bevorzugen weiterhin das installierte hicolor-Icon.
- `FloatingWindow` verwendet `implicitWidth` / `implicitHeight`.
- Wird das einzige Manager-Fenster geschlossen (z. B. über Hyprland `SUPER+Q`), beendet sich auch der Quickshell-Prozess.
- `Ctrl+Q` und `Escape` schließen den Manager ebenfalls vollständig.
- `manager.sh` baut den Katalog vor jedem Start idempotent neu auf, damit neue GUI-Metadaten sofort verfügbar sind.
- Die GUI bleibt eine reine Oberfläche über `install.sh`, `uninstall.sh`, `repair.sh` und die generierten Launcher.

## Start

```bash
./manager.sh
```

Vor produktiven Install-/Uninstall-Aktionen sollte dieser UI-Prototyp zunächst weiter visuell und funktional getestet werden.
