# Punkt 6 – App-Katalog konsolidieren (v0.3.8)

## Ziel

Alle `apps/*.conf` enthalten nur noch app-spezifische Daten. Verhalten, das für eine ganze Kategorie gilt, wird einmal zentral in `config/categories.json` definiert. Dadurch müssen neue Apps einer bestehenden Kategorie keine Applet-, Notification- oder Shared-Hyprland-Schalter mehr kopieren.

## Pflichtfelder pro App

- `APP_ID`
- `APP_NAME`
- `APP_GENERIC_NAME`
- `APP_COMMENT`
- `APP_URL`
- `APP_CATEGORIES`
- `APP_KEYWORDS`
- `APP_CATALOG_CATEGORY`
- `MOZ_APP_REMOTINGNAME`
- `WINDOW_CLASS`
- `ICON_NAME`
- `USE_OPAQUE_TAG`
- `NOTIFICATION_MATCH`
- mindestens eines aus `ICON_URL` oder `ICON_LOCAL_FILE`

## Optionale app-spezifische Felder

- `ICON_URL`
- `ICON_LOCAL_FILE`

Weitere optionale Felder dürfen künftig ergänzt werden, solange sie wirklich app-spezifisch sind. Kategorie-Verhalten gehört nicht in `apps/*.conf`.

## Zentral verwaltete Kategorie-Felder

Folgende Werte dürfen nicht mehr in einzelnen App-Dateien stehen:

- `APPLET_VISIBLE`
- `APPLET_SHOW_BADGE`
- `APPLET_NOTIFICATION_PREVIEW`
- `HYPR_SHARED_TAG`
- `HYPR_SHARED_OWNER`
- `HYPR_SHARED_WORKSPACE`
- `HYPR_SHARED_LOCAL_DECL`
- `HYPR_SHARED_RULE_MARKER`
- `HYPR_SHARED_CREATE_TAG`
- `HYPR_SHARED_KEYBIND`

Die Quelle dafür ist ausschließlich `config/categories.json`.

## Aktuelle Kategorien

### `messaging`

Native Bar-Applets sind sichtbar, Badge und Notification-Vorschau sind aktiv. Die App wird in Caelestias vorhandenen `communication_app_tag` eingehängt; die gemeinsame Communication-Infrastruktur gehört Caelestia und wird von WebApps nicht entfernt.

### `ai`

Native Bar-Applets sind sichtbar; Badge und Notification-Vorschau sind standardmäßig aus. Es gibt keinen gemeinsamen Special-Workspace-Tag.

### `streaming`

Kein Bar-Applet. Die Apps werden in `special:streaming` einsortiert. Die von Caelestia WebApps verwaltete Streaming-Infrastruktur einschließlich `SUPER+Y` wird zentral über die Kategorie beschrieben.

## Validierung

Einzelinstallationen validieren die rohe App-Datei zuerst gegen das Schema und wenden danach die Kategorie-Defaults an. Damit gibt es verständliche Fehler, wenn z. B. eine unbekannte Kategorie benutzt oder ein zentral verwaltetes Feld wieder in eine einzelne App kopiert wird.

Alle Definitionen können zusätzlich gemeinsam geprüft werden:

```bash
./catalog.sh validate
```

Das prüft außerdem Dateiname gegen `APP_ID`, URL-/Klassenformate, Bool-Werte, Semikolon-Abschluss der Desktop-Kategorien/Keywords sowie lokale Icon-Fallbacks.

## Neue App hinzufügen

Für eine neue Messaging-App sind daher nur noch die individuellen Werte nötig; `APPLET_VISIBLE`, Badge, Vorschau und `communication_app_tag` werden automatisch aus `APP_CATALOG_CATEGORY="messaging"` abgeleitet. Dasselbe Prinzip gilt für AI und Streaming.
