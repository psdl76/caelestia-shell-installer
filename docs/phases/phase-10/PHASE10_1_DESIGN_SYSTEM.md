# Phase 10.1 – manager-design-system-01

## Goal

Introduce a stable, project-owned design layer before changing the visual language.

## Files

- `manager/style/Theme.qml`: semantic color roles
- `manager/style/Tokens.qml`: spacing, shape, typography, control-size and motion tokens
- `manager/style/qmldir`: local singleton registration

## Contract

- `manager/shell.qml` contains no raw hex color literals.
- Repeated radii, spacing, font sizes and animation durations use `Style.Tokens`.
- Values intentionally preserve the accepted Phase-9 appearance.
- These tokens are owned by Caelestia WebApps and do not import private Caelestia Shell QML APIs.
- A future theme adapter may populate equivalent semantic roles from stable/public Caelestia-generated data without changing manager components.
