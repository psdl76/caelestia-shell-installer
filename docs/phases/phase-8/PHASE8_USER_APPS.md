# Phase 8 – userapps-01

## Scope

Add the first real Add/Edit WebApp Wizard and persistent user-owned app definitions.

## Persistence contract

User definitions live in:

`$XDG_CONFIG_HOME/caelestia-webapps/apps/`
or, by default:
`~/.config/caelestia-webapps/apps/`

They are not stored in the project tree.

## API

- `user-create JSON`
- `user-update ID JSON`
- `user-delete ID`

The Catalog v2 generator merges built-in and user definitions.
Built-in IDs may not be shadowed.

## Wizard

Fields:
- Name
- immutable App ID
- URL
- existing category
- optional icon URL

The manager never writes definition files itself. It calls the versioned CLI API.

## Deliberate limits of this checkpoint

- Existing categories only (AI / Messaging / Streaming).
- Icon input is URL-based; local file picker comes later.
- Creating a definition does not auto-install it. The new app appears with `Installieren`, keeping definition creation separate from engine installation.
