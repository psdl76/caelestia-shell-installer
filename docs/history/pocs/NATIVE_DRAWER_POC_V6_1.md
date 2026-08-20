# Native Sidebar PoC v6.1 — Caelestia-style uninstall page

Live video testing showed that v6's uninstall confirmation was visually wrong:
it was a semi-transparent overlay above the app list.

v6.1 removes that overlay completely.

The WebApps content now has its own two-page horizontal track:
- page 0: app list
- page 1: fully opaque uninstall confirmation

Clicking Entfernen slides the complete WebApps surface to the confirmation page using
Caelestia `Anim`. Abbrechen slides back to the list. The confirmation uses the native
surface/error-container colours and is never transparent.

Backend uninstall behavior is unchanged.
