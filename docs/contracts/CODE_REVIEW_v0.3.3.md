# Code-Review: Caelestia WebApps v0.3.3

Stand: 2026-08-14  
Referenz: unveränderte v0.3.3-Baseline  
Review-Build: v0.3.4

## Ziel dieses Schritts

Punkt 2 des Stabilisierungsplans prüft die Codebasis auf Altlasten, unnötige Komplexität, fragile Shell-Konstruktionen, inkonsistente Metadaten und offensichtliche Wartbarkeitsprobleme. Änderungen in v0.3.4 sind bewusst auf eindeutig verstandene Bereinigungen beschränkt. Größere Verhaltensänderungen bleiben den dafür vorgesehenen späteren Punkten vorbehalten.

## In v0.3.4 bereinigt

### 1. Temporäre Applet-Verzeichnisse

`install_sidebar_applet` und `uninstall_sidebar_applet` arbeiteten mit `mktemp -d`, räumten das Verzeichnis aber nur am regulären Funktionsende auf. Bei einem Fehler konnte es liegen bleiben. Beide Funktionen laufen jetzt in einem Funktions-Subshell und besitzen dort einen `EXIT`-Trap. Dadurch wird das temporäre Verzeichnis auch bei `die`, Python-Patcherfehlern oder einem abgebrochenen Installationsschritt entfernt. Die frühere problematische RETURN-Trap-Variante wird nicht wieder eingeführt.

### 2. Globale Shell-Optionen im Hyprland-Patcher

Zwei Patcher schalteten für die Auswertung von `awk` global `set +e` und anschließend `set -e`. Das ist unnötig fragil, weil die Funktion damit den Fehlerbehandlungszustand der aufrufenden Shell verändert. Der Exit-Code wird jetzt lokal über `if awk ...; then ... else ... fi` ausgewertet.

### 3. Gemeinsame Fehlermeldung

`die()` meldete auch bei `uninstall.sh`, `catalog.sh` und `applet.sh` immer `INSTALLATION ABGEBROCHEN`. Der gemeinsame Text lautet jetzt neutral `VORGANG ABGEBROCHEN`.

### 4. QML-Bereinigung

Unbenutzte Imports wurden aus `WebAppIcon.qml` und `WebAppPopout.qml` entfernt. `Catalog.focusExisting()` führte vorher zwei vollständige Toplevel-Suchen aus (`isRunning()` und anschließend erneut indirekt). Jetzt wird `runningToplevel()` einmal ausgewertet. Das beobachtbare Activate-or-launch-Verhalten bleibt unverändert.

### 5. Desktop-Kategorien

Streaming-Apps deklarierten gleichzeitig `AudioVideo` und `Network` als Hauptkategorien. Gemini und Claude deklarierten `Network` und `Utility`. Das kann `desktop-file-validate` als mehrere Hauptkategorien beanstanden. Streaming verwendet jetzt `AudioVideo;Video;`, Gemini und Claude `Network;`.

### 6. Python-Wartbarkeit

`generate_catalog.py` und der historische Sidebar-Patcher wurden lesbar formatiert. Das Katalogschema und der generierte App-Inhalt wurden dabei nicht verändert. Ein Vergleich des v0.3.3- und v0.3.4-Katalogoutputs ist – abgesehen von `generatedAt` – identisch.

### 7. Release-Artefakte

Der versehentlich enthaltene Python-Bytecode unter `scripts/__pycache__` wurde entfernt. v0.3.4 enthält keine `*.pyc`-Dateien.

## Bewusst noch nicht geändert

Diese Punkte sind echte Review-Funde, gehören aber fachlich zu späteren Schritten des Plans und werden deshalb in Punkt 2 nicht nebenbei umgebaut.

### Hoch: Idempotenz der opaque-Regel bei Sonderzeichen

Die Erkennung der opaque-Zeile baut einen Extended-Regular-Expression-Ausdruck direkt aus `APP_NAME`. Dadurch werden Regex-Sonderzeichen im Anzeigenamen nicht escaped. Das betrifft konkret `Paramount+`: Das `+` wird als Regex-Quantifizierer interpretiert, sodass eine bereits vorhandene Zeile nicht zuverlässig erkannt wird. Dieselbe Konstruktion existiert im Uninstaller.

**Weiter in:** Punkt 3 (Installer idempotent) und Punkt 5 (Uninstaller).

### Hoch: Hyprland-Änderungen sind als Gesamtvorgang nicht atomar

`rules.lua` kann nacheinander für opaque, communication und streaming verändert werden. Scheitert ein späterer Schritt, sind frühere Änderungen bereits live geschrieben, obwohl `hyprctl reload` noch nicht erfolgreich validiert wurde. Backups existieren, aber es gibt noch keinen automatischen Rollback des gesamten Vorgangs.

**Weiter in:** Punkt 3 und Punkt 9.

### Hoch: Uninstaller entfernt Kategorie-Zuordnungen nicht vollständig

Der aktuelle Uninstaller entfernt die klassische opaque-Zeile, aber nicht die App-Klasse aus `communication_app_tag` oder `streaming_app_tag`. Auch gemeinsam angelegte Streaming-Infrastruktur wird nicht auf „letzte Streaming-App entfernt“ geprüft.

**Weiter in:** Punkt 5.

### Mittel: Backups auch bei No-op-Pfaden

`install_communication_rule()` und `install_streaming_rule()` können ein Backup anlegen, bevor eindeutig feststeht, dass tatsächlich eine Änderung nötig ist. Das ist sicher, erzeugt bei wiederholten Installationen aber unnötige Backups.

**Weiter in:** Punkt 3.

### Mittel: Mehrere Notification-Matches werden erzeugt, aber nicht vollständig verwendet

`catalog.json` enthält sowohl `notificationMatch` als auch `notificationMatches`. `Catalog.qml` wertet aktuell nur `notificationMatch` aus, also den ersten Eintrag. Definitionen wie `MagentaTV|Magenta TV` oder `Paramount+|Paramount Plus` profitieren daher nicht von allen angegebenen Varianten.

**Weiter in:** Punkt 8.

### Mittel: Activate-or-launch gilt nur im Applet

Die Applet-Logik fokussiert eine laufende Instanz korrekt. Der normale Caelestia-App-Launcher startet dagegen weiterhin direkt das generierte Shell-Launcher-Skript mit Firefox `--new-instance`. Das Verhalten ist aktuell bewusst so, verhindert aber Doppelstarts nicht systemweit.

**Weiter in:** Punkt 7.

### Mittel: Applet-Live-Installation ist nach der Vorvalidierung noch sequenziell

Die QML-Patches werden vorab vollständig in einem temporären Baum validiert. Beim anschließenden Kopieren in den echten Caelestia-Baum werden jedoch mehrere Dateien nacheinander ersetzt. Ein seltener Schreib-/sudo-Fehler mitten in dieser Phase könnte einen gemischten Zustand hinterlassen. Backups sind vorhanden.

**Weiter in:** Punkt 4 und Punkt 8.

### Niedrig: README enthält historische Inkonsistenzen

Die bestehende README hat u. a. doppelte Versionsüberschriften und historische Formulierungen, die nicht mehr exakt zum jeweiligen Release passen. Das wurde absichtlich nicht im Code-Review umgeschrieben.

**Weiter in:** Punkt 12.

### Niedrig: Keine automatisierte Regressionstestsuite

Syntax- und gezielte Vergleichstests sind möglich, aber noch nicht als dauerhaftes Testframework im Repository hinterlegt.

**Weiter in:** Punkt 11.

## Durchgeführte Prüfungen für v0.3.4

- `bash -n` für alle Shell-Skripte und Launcher-Templates: erfolgreich.
- Python-Quelltexte mit `compile()` geprüft: erfolgreich.
- Katalogausgabe v0.3.3 vs. v0.3.4 verglichen: identisch außer `generatedAt`.
- QML-Dateien auf ausgeglichene geschweifte Klammern geprüft: erfolgreich.
- Keine `__pycache__`- oder `*.pyc`-Artefakte im Paket.
- `set +e` ist aus den Projekt-Shellfunktionen entfernt.

## Ergebnis

v0.3.4 ist ein konservativer Cleanup-Build auf Basis des funktionierenden v0.3.3-Stands. Die größeren Review-Funde sind dokumentiert und den nachfolgenden Stabilisierungspunkten zugeordnet, statt sie unkontrolliert in diesen Schritt hineinzuziehen.
