# Punkt 7 – Firefox/WebApp-Verhalten (v0.3.9)

## Ziel

Die Firefox-WebApp-Laufzeit wird an allen Einstiegspunkten vereinheitlicht. Ein Klick aus dem Caelestia-App-Menü bzw. auf die `.desktop`-Datei darf ebenso wenig eine zweite Instanz erzeugen wie ein Klick auf das native Bar-Applet.

## Profile und Firefox-Identität

Jede WebApp behält ihr eigenes Profil unter `~/.local/share/caelestia-webapps/apps/<id>/profile`. Der normale Firefox-Browserprofilbaum wird nicht verändert. Der Launcher setzt weiterhin pro App `MOZ_APP_REMOTINGNAME` und startet neue Fenster mit `--new-instance --profile <dedicated-profile> --new-window <url>`.

Die tatsächliche Laufzeiterkennung verwendet absichtlich nicht den Prozessnamen `firefox`, sondern die exakte Hyprland-Fensterklasse (`WINDOW_CLASS`/`initialClass`). Dadurch können mehrere verschiedene Firefox-WebApps parallel laufen, ohne miteinander verwechselt zu werden.

## Activate-or-launch

Der normale generierte Launcher prüft nun selbst über `hyprctl clients -j`, ob die WebApp bereits läuft. Falls ja, wird die exakte Fensteradresse fokussiert und Firefox nicht erneut gestartet. Damit gilt activate-or-launch jetzt auch für Caelestias App-Menü und Desktop-Launcher; es ist nicht mehr nur eine Funktion des QML-Applets.

Für Kategorien mit Special Workspace (`messaging`, `streaming`) wird der Workspace nur eingeblendet, wenn er nicht bereits sichtbar ist. Dadurch kann ein Aktivierungsversuch einen bereits offenen Special Workspace nicht versehentlich wieder schließen.

## Setup-Modus / Berechtigungen

`userChrome.app.css` blendet Tabs, Navigation und weitere Browserleisten im normalen App-Modus aus. `userChrome.setup.css` lässt die Firefox-Navigation und damit die UI für Ersteinrichtung und Berechtigungen sichtbar. Der Setup-Launcher schaltet nur für seine Prozesslaufzeit auf dieses Stylesheet und stellt über einen EXIT-/Signal-Trap immer den App-Modus wieder her.

Läuft die WebApp bereits, wird Setup nicht parallel gestartet und `userChrome.css` nicht unter dem laufenden Firefox geändert. Stattdessen wird das vorhandene Fenster aktiviert und der Nutzer aufgefordert, die App vollständig zu schließen und Setup danach erneut zu starten.

## Fehler-/Fallback-Verhalten

Die Activate-or-launch-Erkennung benötigt Hyprland IPC (`hyprctl`) und Python 3 zum sicheren Parsen der JSON-Ausgabe. Ist Hyprland IPC nicht verfügbar, bleibt Firefox selbst die Instanz-/Profil-Lock-Autorität. Die bestehenden Profil- und CSS-Prüfungen bleiben erhalten.

## Regressionstest

`tests/test_firefox_runtime.sh` deckt ab:

- separates WebApp-Profil und `user.js`,
- `MOZ_APP_REMOTINGNAME`,
- `--new-instance`, `--profile` und `--new-window`,
- exakte Erkennung über `WINDOW_CLASS`,
- Fokussieren statt Doppelstart,
- Messaging-Special-Workspace öffnen, ohne einen bereits sichtbaren Workspace zu schließen,
- Setup bei bereits laufender App verweigern und vorhandenes Fenster fokussieren,
- Setup-CSS nach Beenden zuverlässig wieder auf App-CSS zurückstellen,
- normale Browser-UI im App-Modus ausblenden und im Setup-Modus sichtbar lassen.
