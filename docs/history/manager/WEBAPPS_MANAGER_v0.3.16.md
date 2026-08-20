# Caelestia WebApps Manager — v0.3.16

Dieser Stand behebt die fehlenden Icons nicht installierter Apps.

Beim Start führt `manager.sh` ausschließlich GUI-Vorbereitung aus:

1. Paketlokale SVGs werden in einen Store-Icon-Cache gespiegelt.
2. Für Apps ohne gebündeltes SVG wird die vorhandene `ICON_URL` einmalig lokal gecacht.
3. `catalog.json` wird vor jedem Manager-Start neu erzeugt, damit Pfade nie aus einem älteren Paketstand stammen.
4. QML lädt Store-Icons ausschließlich lokal.

Cache: `~/.cache/caelestia-webapps/store-icons/`

Die Installations-, Repair-, Uninstall-, Hyprland-, Firefox- und Caelestia-Logik bleibt unverändert im bestehenden Backend.
