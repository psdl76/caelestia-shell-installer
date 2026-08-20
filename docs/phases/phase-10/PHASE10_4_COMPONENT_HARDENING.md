# Phase 10.4 – manager-caelestia-hardening-01

## Focus

Finish the Manager interaction layer without changing engine semantics.

### Keyboard
- ActionButton/IconButton: Tab focus + Enter/Return/Space activation.
- Category pills: Tab focus + Enter/Return/Space activation.
- Catalog-removal switch: keyboard focus + activation.
- `Ctrl+F`: focus/select search.
- `Escape`: close active destructive dialog or wizard.
- Search `Escape`: clear search first.

### Focus
- Shared visible focus ring using `Theme.focusStrong`.
- Focus ring width centralized in Tokens.

### Resilience
- Long app names are elided and show full text on hover.
- Header/search layout gets sensible minimum widths.
- Confirmation title elides safely.
- Better empty state distinguishes search miss vs empty category.

### Architecture
No backend, CLI, Firefox, Hyprland, catalog, ownership or theme-bridge semantics changed.
