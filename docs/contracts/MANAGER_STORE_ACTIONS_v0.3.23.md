# Interactive Store Actions — v0.3.23

The WebApps Manager remains a thin GUI over the existing tested backend:

- **Installieren** → `install.sh <app-id>`
- **Öffnen** → installed per-app launcher (activate-or-launch)
- **Setup-Modus** → installed setup launcher
- **Reparieren** → `repair.sh --app <app-id>`
- **Deinstallieren** → confirmation, then `uninstall.sh <app-id>`

After mutating actions the catalog is rebuilt and watched by QML, so cards update without
restarting the Manager.

The UI deliberately follows Caelestia's interaction language: rounded surfaces, subtle
hover morphing, restrained outlines, compact action surfaces and a custom confirmation
surface instead of exposing backend mechanics to the user.
