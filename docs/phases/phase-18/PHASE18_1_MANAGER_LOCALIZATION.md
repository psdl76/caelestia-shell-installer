# Phase 18.1 — Manager Localization

Status: **ACCEPTED / FROZEN**

## Goal

Add English to the frozen Phase 17.7 Manager without changing its navigation,
motion, lifecycle or standalone architecture. German remains available and the
same QML surfaces are used for both languages.

## Locale contract

The Manager selects its language once at startup in this order:

1. `CAELESTIA_WEBAPPS_LANGUAGE`, when explicitly set;
2. `LC_ALL`;
3. `LC_MESSAGES`;
4. `LANG`;
5. English fallback.

Locale values beginning with `de` select German. All other values select
English. The explicit override accepts `de` or `en`, for example:

```bash
CAELESTIA_WEBAPPS_LANGUAGE=en ./manager.sh
CAELESTIA_WEBAPPS_LANGUAGE=de ./manager.sh
```

## Data boundary

Catalog schema v2 remains frozen. Built-in `comment` values stay in their
existing German source form. In English mode the Manager presents the existing
English `genericName` as the built-in app description. User-created names and
descriptions are user content and are never translated.

Startup preflight events carry German and English labels in the same JSON
record. The Manager chooses the matching fields; CLI commands and their stable
JSON contracts are unchanged.

## Acceptance

Automated candidate gate:

```bash
bash tests/run_phase18_1_gate.sh
```

## Live acceptance

The real Manager was launched in the developer's Hyprland/Quickshell session on
2026-08-20 with `CAELESTIA_WEBAPPS_LANGUAGE=en` and then with
`CAELESTIA_WEBAPPS_LANGUAGE=de`. The user accepted both language modes after
checking the catalog, WebApp info/actions, applet settings, add/edit wizard,
confirmation dialog, About page and back/Escape navigation.

Phase 18.1 is accepted and frozen. Release 0.4.1 carries this localization on
top of the unchanged Phase 16.8 lifecycle and Phase 17.7 visual baseline.
