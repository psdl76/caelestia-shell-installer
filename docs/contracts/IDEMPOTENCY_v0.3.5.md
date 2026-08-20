# Punkt 3 – Installer idempotent machen

Version: **v0.3.5**  
Basis: **v0.3.4**

## Ziel

Eine bereits korrekt installierte WebApp darf bei erneutem Aufruf von `install.sh` keinen anderen verwalteten Endzustand erzeugen. Insbesondere sollen keine doppelten Hyprland-Einträge, keine überflüssigen Backups, keine unnötigen Cache-Rebuilds und keine wiederholten QML-Umschreibungen entstehen.

## Änderungen

### 1. Dateien werden nur noch bei tatsächlicher Änderung ersetzt

`lib/common.sh` besitzt jetzt gemeinsame Hilfsfunktionen für vergleichendes Installieren:

- `files_equal`
- `install_file_if_changed`
- `copy_file_if_changed`
- `render_template_if_changed`

Vorhandene Dateien werden mit dem neu erzeugten Inhalt verglichen. Nur bei einer echten Inhaltsänderung wird ein Backup erstellt und die Datei ersetzt.

Davon profitieren:

- `user.js`
- `userChrome.css`
- App-/Setup-CSS
- normaler Launcher
- Setup-Launcher
- Desktop-Datei
- Installationsmetadaten
- Icons

### 2. Desktop- und Icon-Caches werden nicht unnötig neu aufgebaut

`update-desktop-database` wird nur ausgeführt, wenn sich die `.desktop`-Datei tatsächlich geändert hat. Der GTK-Icon-Cache wird nur aktualisiert, wenn das installierte SVG einen anderen Inhalt erhalten hat.

### 3. Hyprland-Regeln erkennen vorhandene Apps literal

Die alte Erkennung des `opaque_tag` kombinierte Fensterklasse und Anzeigenamen in einem regulären Ausdruck. Dadurch konnten Sonderzeichen in Anzeigenamen – insbesondere `Paramount+` – die Duplikaterkennung verfälschen.

v0.3.5 sucht die quoted `WINDOW_CLASS` nun literal innerhalb des jeweiligen `tagged_rule()`-Blocks. Dadurch sind Anzeigenamen für die Erkennung irrelevant.

Zusätzlich wird nach einem Patch geprüft, dass die Klasse im Zielblock genau einmal vorhanden ist.

### 4. Gemeinsame Streaming-Struktur wird nur einmal angelegt

Folgende Elemente werden vor einer Änderung explizit geprüft:

- `streaming_app_tag`-Deklaration
- `tagged_rule(streaming_app_tag, ...)`
- `create_tag(streaming_app_tag, ...)`
- `SUPER+Y`-Streaming-Keybind
- App-Klasse im `streaming_app_tag`

Bereits vorhandene verwaltete Elemente werden nicht erneut geschrieben und erzeugen keine neuen Backups.

### 5. Messaging-Regeln sind ebenfalls wiederholbar

Die App-Klasse wird nur ergänzt, wenn sie im `communication_app_tag` noch nicht vorhanden ist.

### 6. Hyprland wird nur bei einer tatsächlichen Änderung neu geladen

`HYPR_CHANGED` verfolgt, ob `rules.lua` oder `keybinds.lua` wirklich geändert wurden. Ein zweiter identischer Installationslauf überspringt `hyprctl reload`.

### 7. `catalog.json` bleibt bei identischem Zustand byte-stabil

`generate_catalog.py` vergleicht den neuen App-Inhalt mit einem vorhandenen Katalog. Sind `schemaVersion` und `apps` identisch, wird die Datei nicht neu geschrieben. Dadurch ändert sich auch `generatedAt` nicht bei einem reinen Wiederholungslauf.

### 8. Caelestia-Applet wird nur bei echten Änderungen zurückgeschrieben

Die gepatchten temporären QML-Dateien werden mit den Live-Dateien verglichen. Nur unterschiedliche Dateien werden gesichert und ersetzt. Auch das Verzeichnis `modules/bar/webapps` wird nur neu installiert, wenn sich sein Inhalt unterscheidet.

Die Bar-Patcher wurden zusätzlich whitespace-stabil gemacht: Zweimaliges Anwenden desselben Patches erzeugt nun byte-identische QML-Dateien und keine anwachsenden Leerzeilen.

## Automatisierte Prüfungen

Neu unter `tests/`:

### `test_idempotency.sh`

Führt vollständige Installationen in einem isolierten temporären `$HOME` mit Stub-Kommandos aus und installiert jede Test-App zweimal.

Abgedeckt werden:

- `paramount-plus` – Streaming und Sonderzeichen `+` im Anzeigenamen
- `chatgpt` – AI / opaque-only
- `google-messages` – Messaging / communication tag

Nach dem zweiten Lauf wird geprüft:

- verwaltete Dateien sind byte-identisch,
- `catalog.json` ist unverändert,
- Hyprland-Dateien sind unverändert,
- keine zusätzlichen Backups wurden erzeugt,
- `SUPER+Y` existiert genau einmal,
- App-Klassen sind in ihren Ziel-Tags nicht dupliziert.

### `test_patch_idempotency.py`

Wendet die QML-/Notification-Patcher jeweils zweimal auf synthetische Fixtures an und prüft auf byte-identische Ergebnisse und genau einen verwalteten Block.

## Testergebnis

```text
PASS: repeated installs are idempotent for streaming, AI and messaging fixtures
PASS: QML/notification patchers are byte-stable on repeated install
```

Zusätzlich geprüft:

- alle Shell-Skripte mit `bash -n`,
- alle Python-Skripte mit `py_compile`.

## Bewusst noch nicht Teil dieses Punkts

Folgende Themen bleiben den bereits geplanten späteren Stabilisierungsschritten vorbehalten:

- vollständige Transaktions-/Rollback-Logik für mehrere Hyprland-Änderungen,
- Upgrade-Migration alter Releases,
- vollständige Symmetrie des Uninstallers,
- Bereinigung gemeinsamer Tags beim Entfernen der letzten App,
- vollständige Nutzung von `notificationMatches`,
- umfassende öffentliche README-/Entwicklerdokumentation.

Damit ist Punkt 3 auf den Installationspfad begrenzt und verändert keine bewusst separat geplanten Uninstall-/Upgrade-Semantiken.
