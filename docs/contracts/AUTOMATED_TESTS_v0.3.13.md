# Automated tests — v0.3.13

Punkt 11 ergänzt einen zentralen Test-Runner unter `tests/run.sh`.

## Ziele

Die Tests laufen ausschließlich gegen Projektdateien und temporäre Verzeichnisse.
Sie dürfen keine echte Caelestia-, Hyprland- oder Firefox-Konfiguration des Benutzers verändern.

## Abgedeckt

- Shell-Syntax aller Shell-Skripte
- Validierung aller App-Definitionen
- isolierte Katalog-Generierung
- Python-Patcher-Syntax und Test-Isolation
- Hyprland-Vertrag: Ownership-Marker, Shared Tags, `SUPER+Y`, transaktionale Bearbeitung
- Schutz vor direkten Zugriffen/Löschoperationen auf reale Benutzerkonfigurationen
- bestehende Regressionstests des Projekts bleiben Bestandteil des Testverzeichnisses

## Ausführen

```bash
./tests/run.sh
```

Jeder Test liefert `PASS` oder `FAIL`; der Runner endet bei mindestens einem Fehler mit einem Exit-Code ungleich 0.

## Hinweis zur Laufzeit

`tests/run.sh` führt auch die bereits vorhandenen Integrations-/Regressionstests aus.
Dadurch ist der Gesamtlauf absichtlich gründlicher als ein reiner Syntax-Smoke-Test und kann
je nach System deutlich länger dauern. Einzelne Tests können jederzeit direkt mit
`bash tests/test_<name>.sh` ausgeführt werden.
