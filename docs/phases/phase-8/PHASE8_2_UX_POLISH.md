# Phase 8.2 – manager-ux-polish-01

## UX changes

- Replaces ambiguous `×` with the Material Symbols trash icon.
- Distinguishes `Deinstallieren` from `Aus Katalog entfernen`.
- User App wizard supports Tab / Shift+Tab between text fields and save action.
- Enter on the save action submits; Escape cancels.
- New dialogs focus the first field automatically.
- If an installed WebApp is currently running, the confirmation changes to
  `Schließen & deinstallieren`.

## Safety contract

`uninstall-close` sends a graceful Hyprland close request to every matching
WebApp window. It waits up to six seconds for the windows to disappear.
Only then is the existing uninstall engine invoked.

If the window remains open, uninstall is aborted. No SIGKILL fallback is used.
