# Phase 15.2 — Caelestia Plugin PoC 2

Status: EXPERIMENTAL / NOT FROZEN

Validated against Caelestia shell branch:
- branch: `feat/plugins`
- observed commit: `4e288c54`

## Verified API facts

- Plugin search roots include:
  - `$XDG_DATA_HOME/caelestia/plugins`
  - `$XDG_CONFIG_HOME/caelestia/plugins`
  - `CAELESTIA_PLUGIN_PATH`
  - extra `path` entries from `plugins.json`
- `plugins.json` lives at `$XDG_CONFIG_HOME/caelestia/plugins.json`.
- Canonical plugin id is lowercase `author/name`.
- QML URI segments may only contain letters, digits and `_`, and may not start with a digit.
- The loader accepts a normal QQuickItem/QML Item.
- `entryPoint` and `settings` are injected only if the loaded root object declares those properties.
- `bar-entry.properties.name` is matched against a configured bar entry id.
- `bar-popout.properties.entry` is matched to that same id.
- The shell owns popout activation/positioning; the plugin bar entry should not implement its own shell popup.

## Plugin identity

- author: `caelestia_webapps`
- name: `webapps`
- id: `caelestia_webapps/webapps`

## Install test plugin

```bash
./integrations/caelestia/tools/install-plugin-test.sh
```

This copies the plugin to:

```text
~/.config/caelestia/plugins/webapps/
```

It intentionally does not edit `shell.json` or `plugins.json`.

## Enable / disable helper

```bash
./integrations/caelestia/tools/set-plugin-enabled.py on
./integrations/caelestia/tools/set-plugin-enabled.py off
```

The helper preserves existing `path`, `settings`, and unrelated enabled plugin ids.
It refuses to overwrite malformed JSON.

## Bar config

The experimental shell still needs an enabled bar entry with id `webapps`.
Do not add it to the production shell config until the feature-shell test is isolated.

Example entry:

```json
{
  "id": "webapps",
  "enabled": true
}
```

Placement in the `bar.entries` array controls its position.

## Architecture

The adapter only calls:

- `caelestia-webapps list`
- `caelestia-webapps launch <id>`
- `caelestia-webapps-manager`

Core business logic remains outside QML.

## UI placement note

This PoC proves the official `bar-entry` + `bar-popout` path.
It does NOT yet claim that this is the final visual location matching the
existing dashboard Media/Spotify card. The plugin API currently exposes
`dashboard-tab` as a separate entry point; final placement will be decided
after testing the official feature shell and comparing it to the desired
Media-area UX.
