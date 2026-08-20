# Phase 15.3d.2a — Real freedesktop notifications

This is the first real-notification source PoC for the generic per-app applets.

## Architectural boundary

- Does **not** import `qs.services` or any private Caelestia QML API.
- Does **not** become `org.freedesktop.Notifications` and therefore does not
  compete with Caelestia's NotificationServer.
- Observes the public freedesktop `Notify` method calls with `dbus-monitor`.
- Uses the public `desktop-entry` notification hint to map a notification to a
  WebApp id (`whatsapp`, `google-messages`, ...).
- Stores only normalized title/body/timestamp for matching WebApps. Raw image
  data and unrelated desktop notifications are not persisted.

## Deliberate PoC limitation

The watcher is started explicitly in a terminal. Event dismissal/replacement
tracking and automatic lifecycle management are deferred to 15.3d.2b after the
real source has been live-validated.

## Commands

```bash
caelestia-webapps notification-watch
```

Then in another terminal:

```bash
caelestia-webapps status-feed whatsapp
```

The generic QML bar entry and popout continue to poll `status-feed`; no app-
specific renderer was introduced.
