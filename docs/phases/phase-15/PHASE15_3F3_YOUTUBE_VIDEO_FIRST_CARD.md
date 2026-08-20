# Phase 15.3f.3 — YouTube video-first card

This phase separates YouTube's video presentation from the audio-card visual language.

## Changes

- YouTube remains a live `ScreencopyView` preview with the existing deterministic Hyprland/Wayland binding.
- The decorative ambient circles are hidden for video presentations.
- The audio visualizer is hidden for video presentations; the live picture is the motion/hero element.
- The live badge becomes a compact Material-style `LIVE`/`VIDEO` chip with a subtle pulsing status dot while playing.
- Album pills are audio-only.
- Video playback controls are slightly more compact while preserving the existing MPRIS control path.
- Existing YouTube pinning, MPRIS specificity, and active-session routing are unchanged.

## Presentation compatibility

`live_preview` remains supported as the current YouTube wrapper value for regression compatibility. Internally it is classified as a video presentation. `video_preview` is also accepted for a future explicit schema migration.

## Focused tests

- `test_phase15_3f3_youtube_video_card.py`
- `test_phase15_3e4_themed_media_card.py`
- `test_phase15_3e2_fix1_preview_binding.py`
- `test_phase15_3f1_youtube_pin.py`
- `test_phase15_3f2_active_mpris_session.py`
