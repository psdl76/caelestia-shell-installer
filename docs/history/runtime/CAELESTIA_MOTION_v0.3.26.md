# Caelestia Motion Pass — v0.3.26

Hotfix for the v0.3.25 uninstall modal.

The modal card accidentally assigned `radius` twice:

- static `radius: 26`
- animated `radius: uninstallOverlay.active ? 26 : 38`

QML rejects duplicate property assignments. v0.3.26 removes the static assignment and
retains only the animated radius. No backend logic or other motion behavior changed.
