# Punkt 8 – Applet und Notifications robust machen (v0.3.10)

## Ziel

Die native Caelestia-Bar-Integration wird gegen die inzwischen produktiv genutzten Firefox-Webnotifications gehärtet. Im Mittelpunkt stehen eindeutiges Notification-Matching, sichere Notification-Locks, Badges/Mehrfachnachrichten, Senderbilder, Klick-Aktionen, Fokus vorhandener WebApps und die Verwendung nativer Caelestia-/Material-3-Farben.

## Änderungen

### Notification-Matching

`Catalog.qml` nutzt jetzt alle vom Katalog gelieferten `notificationMatches` statt nur des ersten Eintrags. Dadurch funktionieren Definitionen wie `MagentaTV|Magenta TV` oder `Paramount+|Paramount Plus` vollständig.

`desktopEntry` bleibt die bevorzugte Identität. Zusätzlich werden `.desktop`-Suffixe normalisiert und folgende projekt-eigenen Identitäten akzeptiert:

- App-ID, z. B. `whatsapp`
- `WINDOW_CLASS`
- Desktop-Datei-Basename `caelestia-webapp-<id>`

Erst danach greift der Text-Fallback über `appName`, `summary` und `body`.

### Kategorie-/Workspace-Logik

Der generierte Katalog enthält jetzt `specialWorkspace`, abgeleitet aus `config/categories.json`. Das Applet enthält dadurch keine fest verdrahteten `messaging`-/`streaming`-Sonderfälle mehr. Neue Kategorien können ihren Special Workspace zentral deklarieren.

### Notification-Locks

`WebAppIcon.qml` gibt nicht mehr zugehörige Locks explizit frei. Frühere Versionen entfernten solche Objekte nur aus der lokalen Referenzliste; bei geänderten Match-/Katalogdaten konnte dadurch ein von Caelestia bereits geschlossenes `NotifData` unnötig gehalten werden.

Unlocks sind defensiv gegen bereits zerstörte/anderweitig bestätigte Notification-Objekte abgesichert.

### Mehrere Nachrichten, Badge und Vorschau

- Badge zählt weiterhin alle zum Applet gehörenden Notifications und begrenzt die Darstellung auf `99+`.
- Popout zeigt bis zu drei Nachrichten.
- Weitere Nachrichten werden mit `+ N weitere` angezeigt.
- Nur die angeklickte Nachricht wird beim Klick bestätigt.
- Klick auf das Bar-Icon bestätigt weiterhin alle dort gehaltenen Notifications und aktiviert anschließend die App.

### Senderbilder

Vorhandene Notification-Bilder werden kreisförmig maskiert. Kann ein geliefertes Bild nicht geladen werden, wird nun zuverlässig das App-Icon als ebenfalls maskierter Fallback dargestellt, statt einen leeren Avatarbereich zu zeigen.

### Klick und Fokus

Beim Klick auf eine Notification wird eine bereits laufende WebApp zuerst über ihre exakte Hyprland-Klasse fokussiert und der passende Special Workspace aktiviert. Danach wird – falls vorhanden – die `default`-Action der Notification ausgeführt. Fehlt eine nutzbare Action, greift der bestehende Activate-or-launch-Fallback.

### Theme

Bar-Badge und Popout verwenden weiterhin native Caelestia-Komponenten (`StyledText`, `StyledRect`, `StateLayer`, `MaterialIcon`, `ColouredIcon`) und Material-3-Palettenwerte. Sekundäre Texte verwenden explizit `m3onSurfaceVariant`; Badge-Kontrast nutzt `m3primary` / `m3onPrimary`.

## Tests

Neu:

```bash
./tests/test_applet_notifications.py
```

Der Test prüft Katalog-/Kategorie-Daten, alle Notification-Match-Varianten, desktopEntry-Normalisierung, Lock-Lifecycle, Drei-Nachrichten-Vorschau, Avatar-Fallback, Default-Action, Fokuslogik, dynamischen Öffnen-Button und Theme-Tokens.

Die bisherigen Patch-Idempotenztests bleiben Bestandteil der Regressionstests.
