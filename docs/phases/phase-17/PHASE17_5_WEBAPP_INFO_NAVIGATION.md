# Phase 17.5 — WebApp Info Navigation

Status: **ACCEPTED / FROZEN**

## Goal

Adopt the Caelestia Nexus `Apps → All apps → App info` information architecture
for the WebApps catalog. The catalog is for selection; the WebApp info page is
the single home of entry-specific actions and metadata.

## Catalog contract

- Every catalog row is one connected, fully clickable navigation item.
- Rows show icon, name, description, running state and a trailing chevron.
- Install, open, applet and More Actions buttons do not appear in catalog rows.
- Clicking any installed or uninstalled catalog entry opens `WebApp-Info` with
  the established forward StackPage animation.
- The global `+ WebApp` action remains in the catalog header because it creates
  a new entry rather than acting on the selected entry.

## WebApp info contract

- The page begins with a back header followed by the selected WebApp's large
  icon, name and description, matching Nexus `AppInfo.qml`.
- Install or open/focus is the primary action in the WebApp section.
- Supported installed applets expose activation and capability settings in an
  Applet section.
- Setup, repair and editing live in Verwaltung; removal is isolated in its
  destructive section.
- Status, source, App ID and URL appear as connected Details rows.
- The detail body scrolls independently while the page header remains stable.

## Lifecycle behavior

After install, uninstall, repair or catalog mutation, the selected WebApp object
is rebound to the refreshed catalog entry. If the entry was deleted, the page
returns to the catalog. Existing CLI argument-list, confirmation, applet and
persistence contracts remain unchanged.

## Reference and architecture boundary

The layout and navigation pattern follows official Caelestia Shell
`modules/nexus/pages/apps/AllApps.qml` and `AppInfo.qml` at commit `b1c9bbd`.
The Manager uses only project-owned QML equivalents and no private Caelestia
imports.
