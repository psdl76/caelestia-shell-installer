# Native Sidebar PoC v4

This is the cleaned-up UI checkpoint after the live theme test.

## Confirmed fixes

- `WebAppsContent.qml` imports `qs.services`, so direct references to
  `Colours.palette.*` resolve in the same context as Caelestia's own components.
- WebApps text uses the native Material theme colours instead of falling back to black.
- The v3 horizontal page-track transition is retained unchanged.
- The single sliding active-tab pill is retained unchanged.
- The user's original notification sidebar is still preserved verbatim at install time.
- Caelestia's native Sidebar Wrapper / PanelBg / BlobRect / deformation pipeline remains untouched.

## Scope

v4 intentionally does not add install, uninstall, setup or repair actions yet.
It is the stable native-sidebar UI checkpoint before wiring the existing v0.3.27
backend actions into the QML frontend.
