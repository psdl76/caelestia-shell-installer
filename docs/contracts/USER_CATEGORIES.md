# User category contract

Custom WebApp categories are persistent user configuration. They extend, but
never modify or shadow, the package-owned category schema.

## Storage and identity

- File: `$XDG_CONFIG_HOME/caelestia-webapps/categories.json`, falling back to
  `~/.config/caelestia-webapps/categories.json`.
- Schema version: `1`.
- Each entry stores an immutable slug ID, a user-visible label and one supported
  Material-symbol key.
- Writes are atomic. The directory is private (`0700`) and the file uses
  permissions `0600`.

The label may be changed without rewriting WebApp definitions because those
definitions reference the immutable ID. Package categories and the synthetic
Manager IDs `featured`, `all` and `installed` are reserved.

## Runtime behavior

User categories receive neutral defaults: no applet visibility or badge, no
notification preview and no shared Hyprland tag, workspace, rule or keybind.
The merged category view is used by user-definition validation, Catalog v2,
install, repair, uninstall and safe orphan recovery. The frozen package-owned
category schema and built-in definition validator remain unchanged.

Catalog v2 continues to contain populated categories only. CLI `list` adds
`availableCategories`, which also contains empty categories and exposes their
label, icon, source, count and deletion eligibility to the Manager.

## Mutation rules

The public CLI operations are:

```text
user-category-create JSON
user-category-update ID JSON
user-category-delete ID
```

Create/update payloads contain `label` and `icon`. Delete is allowed only when
no app definition and no installed metadata refer to the category. Mutations
run under the global engine lock; a failed Catalog/Registry rebuild restores
the previous category file.
