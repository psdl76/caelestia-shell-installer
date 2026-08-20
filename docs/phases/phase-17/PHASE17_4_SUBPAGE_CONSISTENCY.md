# Phase 17.4 — Manager Subpage Consistency

Status: **IMPLEMENTATION CANDIDATE**

## Goal

Every embedded Manager workflow uses one Caelestia Nexus visual grammar. A
WebApp-specific page must not fall back to independent cards, form labels,
button pills or native popups.

## Shared page contract

- More Actions, WebApp create/edit and applet settings use the same page header
  with back action, title and subdued subtitle.
- Sections use the project-owned Nexus-style `SectionHeader`.
- Related controls use connected `surfaceContainer` rows with large outer and
  small inner corners and compact spacing.
- Primary text uses `onSurface`, descriptions use `outline`, and control values
  use the established Manager semantic palette roles.
- Hover and press feedback always uses the shared rounded `StateLayer`.

## Control contract

- Applet capabilities use one connected toggle group rather than individually
  outlined cards.
- WebApp identity fields use connected labelled rows with the input aligned on
  the right, matching Nexus `TextFieldRow`.
- Category and icon source use a project-owned styled select row and animated
  popout; native menus and tooltips are not used.
- Conditional icon URL/file rows remain connected to the appearance group.
- The icon preview is a normal grouped settings row.
- The destructive confirmation remains modal by design, but its optional
  catalog-removal switch uses the same toggle-row component.

## Reference and architecture boundary

The implementation follows the official Caelestia Shell `PageBase`,
`SectionHeader`, `ConnectedRect`, `TextFieldRow`, `ToggleRow` and state-layer
patterns reviewed at commit `b1c9bbd`. All equivalents are project-owned and do
not import private `qs.*` or `Caelestia.*` modules. Frozen CLI, catalog,
lifecycle, applet and persistence behavior is unchanged.
