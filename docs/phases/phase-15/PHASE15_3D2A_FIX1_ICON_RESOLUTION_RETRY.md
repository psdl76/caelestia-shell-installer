# Phase 15.3d.2a-fix1 — deterministic icon metadata retry

Live finding after enabling the real freedesktop notification watcher:
notification status and badges were available, while both WhatsApp and Google
Messages icons could remain unresolved after the first shell startup.

The generic bar entry now retries only the catalog/list metadata lookup while
`iconSource` is empty. The retry stops automatically once the source resolves.
This is state-driven and does not delay rendering with a fixed startup sleep.
The existing Loader/Image.Ready/MultiEffect hardening remains unchanged.
