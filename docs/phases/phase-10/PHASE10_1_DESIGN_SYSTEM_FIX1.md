# Phase 10.1 fix1

Fixes an invalid QML token reference introduced while replacing the original
`radius: 4.5` value.

Before:
`Style.Tokens.radiusXs.5`

After:
`Style.Tokens.radiusStatusDot`

`radiusStatusDot` is a real-valued token set to `4.5`, preserving the previous
appearance without raw magic numbers in `shell.qml`.
