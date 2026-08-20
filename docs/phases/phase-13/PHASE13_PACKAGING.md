# Phase 13 – packaging-01

## Goal

Turn the tested standalone project into a package-owned core with a stable
installation contract before any native Caelestia plugin adapter is added.

## Installed layout

System package:

- `/usr/lib/caelestia-webapps/` — package-owned runtime core
- `/usr/bin/caelestia-webapps` — CLI wrapper
- `/usr/bin/caelestia-webapps-manager` — Manager wrapper
- `/usr/share/applications/caelestia-webapps-manager.desktop`

Rootless/local testing uses the exact same layout below `~/.local`.

## Ownership boundary

The package owns only its installed core and wrappers. It never owns or removes:

- `$XDG_CONFIG_HOME/caelestia-webapps/apps/`
- `~/.local/share/caelestia-webapps/` — current profile/catalog runtime root
- `~/.local/state/caelestia-webapps/` — current logs/backups/state root
- generated Firefox profiles
- user-created WebApp definitions

A package upgrade atomically replaces the core tree. User data lives outside
that tree and survives both upgrade and package-core removal.

## Rootless installer

```bash
./packaging/install-core.sh
caelestia-webapps list
caelestia-webapps-manager
./packaging/uninstall-core.sh
```

Use `--prefix /some/path` for isolated testing.

## Arch prototype

`packaging/build-arch-package.sh` creates a runtime source tarball, injects its
SHA-256 into `PKGBUILD.in`, and invokes `makepkg` on Arch Linux.

The PKGBUILD is intentionally marked with a custom/pending license placeholder.
A real project license must be selected before public AUR publication.

## Automated acceptance candidate

Phase 13 packaging gate: **15/15 PASS**.

Full current suite after packaging changes: **58/58 PASS**.

The build container used for this checkpoint does not provide Arch `makepkg`,
so the final pacman package build itself must be exercised on a real Arch
system. The runtime tarball, fixed SHA-256 PKGBUILD input, installed-prefix
lifecycle and package ownership contracts are tested here.
