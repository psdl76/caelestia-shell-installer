# Phase 19 — AUR and Community Launch

Status: **AUR CANDIDATE VERIFIED / ACCOUNT REGISTRATION BLOCKED**

## Goal

Prepare Caelestia WebApps for public discovery without changing the frozen
Phase 18 product behavior. This phase covers repository presentation, AUR
metadata and community launch material only.

## Completed

- public GitHub repository, v0.4.1 release and GPL-3.0-only license;
- locally verified v0.4.2 branded release candidate;
- final catalog and WebApp-info screenshots without private desktop content;
- user-oriented README with an explicit unofficial-project notice;
- GitHub discovery topics and Discussions;
- AUR package base `caelestia-webapps` confirmed available;
- AUR `PKGBUILD` and synchronized `.SRCINFO`;
- source download, checksum and package layout verified from the public v0.4.1
  release and locally regenerated for v0.4.2;
- clean Arch chroot build completed successfully with `extra-x86_64-build`;
- the final `checkpkg` lookup was skipped because no repository package named
  `caelestia-webapps` exists yet; this does not invalidate the package build;
- `namcap` review completed; its runtime-dependency warnings are understood and
  intentionally retained;
- copy-ready Caelestia, Hyprland and German community launch texts.

## External blocker

The AUR currently rejects new account registrations as a temporary security
measure. Arch staff state that there is no manual onboarding path. Until public
registration reopens, no AUR SSH identity can be associated with a new account
and the package cannot be pushed.

Do not ask Arch staff for manual account creation and do not publish an AUR
installation command before the package page exists.

## Remaining acceptance

1. register the AUR account when registration reopens;
2. create and register a dedicated AUR SSH key;
3. push only `PKGBUILD` and `.SRCINFO` to the AUR package repository;
4. install `caelestia-webapps` through an AUR helper in a real session;
5. replace the README's pending statement with the live AUR command;
6. publish the prepared community announcements.
