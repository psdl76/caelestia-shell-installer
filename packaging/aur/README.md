# AUR publishing workspace

The AUR package base is `caelestia-webapps`. Only `PKGBUILD` and `.SRCINFO`
belong in the external AUR Git repository.

Before every AUR update:

1. build the deterministic runtime archive with
   `packaging/make-runtime-tarball.sh` after the release candidate is frozen;
2. update `pkgver`, `pkgrel`, release URL and the archive's exact `sha256sums`
   in `PKGBUILD`;
3. regenerate `.SRCINFO` with `makepkg --printsrcinfo`;
4. run `tests/run_phase19_aur_gate.sh`; it rebuilds the local archive and
   rejects a stale checksum or unsynchronized `.SRCINFO`;
5. run `makepkg --cleanbuild --force` and inspect the package;
6. run `namcap PKGBUILD` and `namcap` on the built package;
7. copy only `PKGBUILD` and `.SRCINFO` to the AUR checkout;
8. review the AUR diff before committing and pushing.

New AUR accounts require registration at `https://aur.archlinux.org/register`
and a dedicated SSH key registered in the account profile. Do not reuse or
commit the private key.
