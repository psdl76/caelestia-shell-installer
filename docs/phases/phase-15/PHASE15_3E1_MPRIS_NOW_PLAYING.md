# Phase 15.3e.1 — Generic MPRIS Now Playing

- Uses the public `playerctl` CLI as the MPRIS boundary; no private Caelestia imports.
- Matches a generic browser MPRIS player to a WebApp using `xesam:url` hostname vs catalog URL hostname.
- Protocol v1 media state: title, subtitle/artist, album, artwork, playing, progress, player, url.
- GenericStatusPopout renders artwork, title/subtitle, progress and playing/paused state.
- Adds thin YouTube bar-entry/popout wrappers (`webapp-youtube`) to prove a second status kind uses the same generic renderer.
- Playback actions are intentionally deferred to 15.3e.2; this checkpoint validates discovery/matching/rendering first.

Runtime dependency for this phase: `playerctl`.
