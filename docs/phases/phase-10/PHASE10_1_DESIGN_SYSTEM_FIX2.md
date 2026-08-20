# Phase 10.1 fix2

QML reserves the `onXxx` naming shape for signal handlers. The semantic color
role `onPrimary` therefore caused Theme.qml to fail loading.

Renamed:
- `onPrimary` -> `primaryContent`

The visual color value remains unchanged (`#102028`).

A regression test now rejects any Theme property matching `on[A-Z]...`.
