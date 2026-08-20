# Phase 9 – ownership-01

## Goal

Make Built-in Apps and User Apps explicit ownership domains.

## Ownership contract

Built-ins:
- definitions live in the package tree
- `source=builtin`
- `owner=package`
- not editable as definitions
- not removable from catalog
- may be replaced by package upgrades

User Apps:
- definitions live in `$XDG_CONFIG_HOME/caelestia-webapps/apps/`
- `source=user`
- `owner=user`
- editable
- removable from catalog
- survive package upgrades

## Invariants

- User App IDs may never shadow Built-in IDs.
- Repair and upgrade must not rewrite or delete user definition files.
- Catalog v2 merges both sources but preserves source + ownership metadata.
- The manager may display ownership, but it does not implement ownership rules.
