# Phase 15.3f.4-fix1 — Firefox BiDi session lifecycle + diagnostics

Live diagnosis showed that Firefox 153 correctly listens on the configured loopback
remote-debugging port, while `browser-video-state` still returned `available:false`.

The important Firefox behavior is that closing the WebSocket only unregisters the
connection; it does not delete the active WebDriver BiDi session. Firefox currently
allows one active BiDi session, so short-lived polling must explicitly send
`session.end` before closing the socket.

Fixes:

- Every successful `session.new` is paired with `session.end` in `finally`.
- Explicit spec-shaped capabilities are used for `session.new`.
- WebSocket ping frames receive proper pong replies.
- Connect/command timeouts are less aggressive.
- `browser-video-state` now returns diagnostics (`stage`, `error`, `port`,
  matching context count/url, cleanup result) when the bridge is unavailable.
- Regression test performs two consecutive polls against a one-session fake server;
  the second poll only succeeds if the first session was cleaned up.

Because an older build can leave an orphaned BiDi session inside a running Firefox,
Firefox must be fully restarted once after installing this fix.
