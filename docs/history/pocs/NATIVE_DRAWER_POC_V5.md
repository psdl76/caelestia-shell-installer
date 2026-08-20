# Native Sidebar PoC v5 — Open + Install

v5 is the first functional native-sidebar build.

- Installed app: **Öffnen** calls its generated per-app launcher. That launcher remains
  responsible for activate-or-launch and duplicate-window protection.
- Available app: **Installieren** calls a small user-local action bridge.
- The bridge validates the app id and delegates to the existing tested `install.sh`.
- After installation the catalog is rebuilt and the watched QML catalog reloads, so the
  card changes from `Installieren` to `Öffnen` without restarting Caelestia.
- Only one mutating action can run at once.
- A native inline status surface reports progress/success/failure.
- Setup, Repair and Uninstall are deliberately not part of v5.
