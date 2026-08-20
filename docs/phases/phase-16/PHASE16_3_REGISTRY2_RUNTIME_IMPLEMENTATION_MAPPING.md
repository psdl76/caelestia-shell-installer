# Phase 16.3 registry2 — Runtime / Implementation Mapping

Status: TEST CANDIDATE

## Ziel

Die in registry1 eingeführte `applet-registry.json` wird jetzt erstmals von echten Phase-15-Runtime-Consumern verwendet. Der alte `statusIntegration`-Kompatibilitätsspiegel im Katalog bleibt vorerst aus Rückwärtskompatibilitätsgründen generiert, ist aber nicht mehr Quelle für Status-Routing oder Notification-Watching.

## Änderungen

- `integration_status_payload()` liest Adapter und Capabilities aus der Applet Registry.
- `integration_status_all()` bestimmt applet-fähige Apps aus der Registry.
- MPRIS/Media-Routing berücksichtigt Registry-`matchHosts` und damit weiterhin spezifische Hosts wie `music.youtube.com` vor `youtube.com`.
- `notification_watch.py` fragt `caelestia-webapps applet-registry` ab und nimmt nur `adapter=notifications` auf.
- Neuer Runtime-Audit `validate-applet-runtime`.
- Der Audit vergleicht die `supported` Registry-Apps mit den tatsächlich im Caelestia-Plugin-Manifest vorhandenen dedizierten BarEntry/Popout-Komponenten.
- Aktueller erwarteter Mapping-Stand: `google-messages`, `whatsapp`, `youtube`, `youtube-music` = 4/4 supported Implementierungen.
- Experimentelle Registry-Einträge benötigen in dieser Phase noch keine dedizierte QML-Komponente.
- Packaging Gate validiert nun zusätzlich das Runtime/Implementation Mapping.

## Nicht geändert

- Keine Installer-/Uninstaller-Kopplung.
- Keine Manager-Aktivierungsschalter.
- Keine Änderung am visuellen oder funktionalen Verhalten der vier bestehenden Phase-15-Applets.
- Keine Entfernung der dedizierten QML-Komponenten oder Manifest-Einträge.

## Live-Test

```bash
PATH="$PWD/bin:$PATH" caelestia-webapps validate-applet-runtime
PATH="$PWD/bin:$PATH" caelestia-webapps status-feed
```

Erwartet im Audit: 21 Registry Apps, 4 supported, 17 experimental, 4 implementedSupported, keine Orphans, `consistent=true`.
