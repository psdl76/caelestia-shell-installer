# Phase 15.3f.9-fix5b — exact pin close guard

Built against the user's actual `feat/plugins` test-shell files.

Verified contracts:
- `Interactions.qml` exposes `required property Bar.BarWrapper bar`
- `Bar.qml` exposes `webappsYoutubePinned`
- `Bar.checkPopout()` owns plugin popout opening
- `Interactions.qml` owns two `popouts.hasCurrent = false` close paths

Fix:
1. Bar guard now returns only when pinned YouTube is already open:
   `webappsYoutubePinned && popouts.hasCurrent && currentName == webapp-youtube`
2. Both real Interactions close paths leave `hasCurrent` untouched while pinned.
3. Hover can reopen the popout after it was closed.
4. Polling reduced from 200 ms to 500 ms.
5. No other media/runtime/icon behavior changed.
