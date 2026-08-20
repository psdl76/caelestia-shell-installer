# Logging & Error Handling — v0.3.12

Punkt 10 vereinheitlicht die Fehlerausgabe der Benutzer-Einstiegspunkte.

## Verhalten

- Jeder fehlgeschlagene Vorgang nennt den aktuellen Schritt und die Ursache.
- Wenn bekannt, werden betroffene Datei, Backup-Verzeichnis und ein konkreter Wiederherstellungshinweis ausgegeben.
- Unerwartete Shell-Fehler nennen Exit-Code und Zeile; das fehlgeschlagene Kommando wird vor der Ausgabe auf typische Credential-Muster (`password`, `token`, `secret`, `api_key`, `Authorization`, `Bearer`) redigiert.
- `repair.sh` verwendet dieselbe zentrale Fehlerbehandlung wie Installer und Uninstaller.
- Hyprland bleibt transaktional: temporäre Kopien werden vor dem Commit validiert; bei Reload-/Configfehlern werden Originale wiederhergestellt.
- Applet- und Uninstall-Transaktionen räumen ihre temporären Arbeitsverzeichnisse über bestehende EXIT-Traps auf; lokale Einmal-Temporärdateien werden nach Verwendung entfernt oder atomar verschoben.
- Logs enthalten weiterhin technische Diagnosedaten, aber keine absichtlich ausgegebenen Zugangsdaten.

## Wiederherstellung

Backups liegen weiterhin unter `~/.local/state/caelestia-webapps/backups/`. Ein Fehler löscht Backups nicht.
