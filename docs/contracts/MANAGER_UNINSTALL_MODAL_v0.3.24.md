# Manager uninstall modal — v0.3.24

The Qt Quick Controls `Dialog` used by v0.3.23 was not reliably attached to the
Quickshell `FloatingWindow` visual tree. As a result, requesting uninstall could
appear to do nothing even though the manager itself had no QML/runtime error.

v0.3.24 replaces that dialog with a normal in-window modal layer:

- state driven by `pendingApp` / `pendingAction`
- dimmed click-blocking background
- Caelestia-style rounded confirmation surface
- explicit Cancel / Remove actions
- Remove invokes the existing `uninstall.sh <app-id>` backend
- catalog refresh behavior remains unchanged

No uninstall/backend logic was reimplemented in QML.
