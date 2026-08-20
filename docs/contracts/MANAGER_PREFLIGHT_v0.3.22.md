# Manager Preflight — v0.3.22

Vor jedem GUI-Start führt `manager.sh` automatisch einen stillen Self-Heal-Preflight aus.

Der schnelle Pfad prüft Paket-/Repair-Version, Versionsmetadaten installierter Apps,
Launcher, Setup-Launcher und Desktop Entries. Ist alles aktuell, wird kein Repair
ausgeführt. Bei veraltetem oder unvollständigem generiertem Zustand wird automatisch
der bereits getestete idempotente Repair-Pfad verwendet; bestehende Applet-Integration
wird dabei wie bisher genau einmal geprüft.

Der Benutzer muss nach einem Paketwechsel nicht mehr manuell `repair.sh`, `upgrade.sh`
oder einzelne `install.sh`-Aufrufe ausführen, nur damit der Manager aktuelle Launcher
verwendet.

Schlägt der Self-Heal fehl, startet der Manager absichtlich nicht mit inkonsistentem
Zustand. Details stehen in `~/.local/state/caelestia-webapps/logs/repair.log`.
