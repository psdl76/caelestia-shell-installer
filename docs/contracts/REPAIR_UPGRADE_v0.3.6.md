# Punkt 4 – Upgrade- und Repair-Pfad härten (v0.3.6)

## Ziel

v0.3.6 führt einen expliziten, wiederholbaren Repair-/Upgrade-Pfad ein. Vorhandene Installationen aus älteren v0.2.x-/v0.3.x-Ständen sollen auf den aktuellen Paketstand normalisiert werden, ohne Benutzeranpassungen außerhalb der von Caelestia WebApps verwalteten Bereiche zu überschreiben.

## Neue Befehle

```bash
./repair.sh
./upgrade.sh
```

`upgrade.sh` ist bewusst nur ein Alias für denselben Reparaturpfad, damit Upgrade und Repair nicht zwei unterschiedliche Codewege entwickeln.

Optional:

```bash
./repair.sh --dry-run
./repair.sh --app chatgpt
```

## Erkennung vorhandener/halber Installationen

Der Repair-Pfad betrachtet eine bekannte App als vorhanden, wenn mindestens eines der folgenden Artefakte existiert:

- `~/.local/share/caelestia-webapps/apps/<id>/installed.conf`
- Firefox-Profil unter `.../apps/<id>/profile`
- Launcher `~/.local/bin/caelestia-webapp-<id>`
- Desktop-Datei `~/.local/share/applications/caelestia-webapp-<id>.desktop`

Damit können auch abgebrochene oder sehr alte Installationen rekonstruiert werden, bei denen `installed.conf` fehlt.

## Versionsmetadaten

Neu installierte bzw. reparierte Apps erhalten in `installed.conf`:

```text
INSTALLER_VERSION="0.3.6"
```

Ältere Installationen ohne Versionsfeld werden als `vor Versionsmetadaten` erkannt und einmalig auf den aktuellen Stand gebracht.

## Applet-Reparatur

v0.3.6 kann eine bestehende WebApp-Applet-Integration auch dann erkennen, wenn die frühere Datei

```text
~/.local/state/caelestia-webapps/applet/enabled
```

fehlt. Als Besitz-/Existenzindikatoren dienen ausschließlich projektspezifische Marker bzw. die alten/neuen WebApp-Modulverzeichnisse.

Der Repair-Pfad normalisiert dabei:

- aktuellen Bar-WebApp-Modulordner,
- StatusIcons-Integration,
- Popout-Integration,
- Notification-Felder/Locks,
- alten v0.2.0-Sidebar-Prototyp,
- verlorenen Applet-State.

### Beschädigter Managed Block

Ein bekannter Upgrade-Fehler ist jetzt reparierbar: Existiert ein

```text
// BEGIN CAELESTIA-WEBAPPS ...
```

Marker, aber der passende END-Marker fehlt, entfernt der Patcher den eindeutig zugehörigen, strukturell noch intakten `Repeater` und installiert den aktuellen Block neu.

Ist auch die QML-Struktur selbst beschädigt, wird weiterhin abgebrochen. Der Repair-Pfad versucht dann ausdrücklich nicht, fremden oder nicht eindeutig zuordenbaren Code zu erraten.

## Legacy-Migrationen

Bestehende v0.3.0-Streaming-Konfigurationen werden weiterhin unterstützt. Insbesondere wird nur der alte, eindeutig von Caelestia WebApps markierte

```lua
create_bind("SUPER + V", fn.toggle("streaming")) -- Caelestia WebApps: Streaming
```

auf

```lua
create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming
```

migriert.

Eigene Benutzer-Binds werden nicht umgeschrieben.

## Schutz von Benutzeranpassungen

Repair arbeitet bei QML nur an:

- expliziten `CAELESTIA-WEBAPPS`-Markern,
- eindeutig erkannten alten WebApp-Repeaters,
- projektspezifischen Imports/Katalogobjekten.

Hyprland-Anpassungen werden weiterhin nur anhand der bekannten Tags, Klassen und eindeutig markierten Streaming-Keybinds ergänzt/migriert.

## Idempotenz

Ein zweiter vollständiger Repair auf einem bereits korrekten v0.3.6-System:

- erzeugt keine zusätzlichen Backups,
- dupliziert keine QML-Blöcke,
- dupliziert keine Hyprland-Einträge,
- schreibt unveränderte App-Artefakte nicht erneut.

## Tests

Neu: `tests/test_upgrade_repair.sh`.

Der Test simuliert unter einem isolierten HOME:

1. eine halbe ChatGPT-Installation nur mit Firefox-Profil,
2. eine halbe Netflix-Installation nur mit Desktop-Datei,
3. einen alten verwalteten `SUPER+V`-Streaming-Bind,
4. ein altes Applet ohne `enabled`-State,
5. einen StatusIcons-Block mit fehlendem END-Marker,
6. alte Sidebar-/Bar-WebApp-Module,
7. eigene Benutzerzeilen in Hyprland und QML,
8. einen Dry-Run,
9. einen zweiten vollständigen Repair.

Erwartetes Ergebnis:

```text
PASS: v0.3.6 reconstructs half-installs, migrates legacy state, preserves user content and is repair-idempotent
```

Zusätzlich bleiben die Tests aus Punkt 3 aktiv.
