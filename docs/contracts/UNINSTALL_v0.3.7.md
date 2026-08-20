# Punkt 5 – Uninstaller vollständig testen und verbessern (v0.3.7)

## Ziel

Eine einzelne WebApp wird vollständig entfernt, ohne fremde Benutzerdateien oder weiterhin benötigte gemeinsame Infrastruktur zu beschädigen.

## Architektur

- Riskante Hyprland-Änderungen entstehen zuerst ausschließlich in einem temporären Transaktionsverzeichnis.
- Temporäre `rules.lua`/`keybinds.lua` werden vor Live-Änderungen auf Nicht-Leere und – wenn verfügbar – mit `luac -p` auf Syntax geprüft.
- Je geänderter Live-Hyprland-Datei entsteht genau ein Backup unmittelbar vor dem Commit.
- Nach erfolgreichem Hyprland-Reload werden nur die Artefakte der gewählten App gelöscht: Profil/App-Daten, Launcher, Setup-Launcher, Desktop-Datei und – sofern nicht geteilt – Icon.
- Der Katalog wird anschließend aus dem realen Installationszustand neu erzeugt.

## Shared-Infrastruktur

App-Definitionen können deklarieren, welchen Shared-Tag sie nutzen und wem die Infrastruktur gehört. Streaming ist `caelestia-webapps`-owned; Communication ist Caelestia-owned. Dadurch gilt:

- Entfernen von Netflix bei verbleibendem YouTube: nur Netflix-Mitgliedschaften verschwinden, `streaming_app_tag`, `special:streaming` und `SUPER+Y` bleiben.
- Entfernen der letzten Streaming-WebApp: die eindeutig markierte, WebApps-eigene Streaming-Regel, Tag-Deklaration, `create_tag` und `SUPER+Y` werden entfernt.
- Entfernen von WhatsApp: die WhatsApp-Mitgliedschaft verschwindet, die native `communication_app_tag`-Infrastruktur bleibt immer erhalten.
- AI-Apps besitzen derzeit keinen Shared-Tag; es wird nur ihre app-spezifische Opaque-Mitgliedschaft entfernt.

## Applet

Die gemeinsame Caelestia-WebApp-Bar-Integration bleibt bestehen, solange mindestens eine installierte App `APPLET_VISIBLE=true` benötigt. Erst nach der letzten solchen App wird der vorhandene marker-basierte Applet-Uninstaller verwendet. Streaming-Apps mit `APPLET_VISIBLE=false` beeinflussen das Applet nicht.

## Sicherheit

Der Uninstaller löscht keine normalen Firefox-Profile und keine pauschalen `~/.config/hypr`-/Caelestia-Verzeichnisse. Änderungen an gemeinsamem Hyprland-Code sind entweder exakt auf App-Mitgliedschaften begrenzt oder setzen explizite projekt-eigene Marker/Metadaten voraus.

## Tests

`tests/test_uninstall_architecture.sh` deckt ab:

1. Streaming-App mit weiterem Consumer – Shared-Infrastruktur bleibt.
2. Letzte Streaming-App – nur WebApps-owned Shared-Infrastruktur wird zurückgebaut.
3. Messaging-App – native Communication-Infrastruktur bleibt.
4. AI-App – nur Opaque-Mitgliedschaft wird entfernt.
5. Benutzerdefinierte, nicht verwaltete Zeilen bleiben erhalten.
6. `rules.lua` erhält pro Deinstallationslauf nur ein Backup.
