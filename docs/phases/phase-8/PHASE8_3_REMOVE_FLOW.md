# Phase 8.3 – manager-remove-flow-01

The trash icon is now the single destructive entry point.

- Built-in + installed: uninstall only.
- User App + installed: uninstall, with optional `Aus dem Katalog entfernen` switch.
- User App + not installed: the same trash icon opens a simple catalog-removal confirmation.
- The switch is OFF every time the dialog opens.
- Running Apps keep the graceful `Schließen & deinstallieren` flow.
- If the switch is enabled, `user-delete` is invoked only after successful close/uninstall.
- A failure before that point prevents catalog removal.
