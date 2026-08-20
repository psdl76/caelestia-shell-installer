# AUR publishing workspace

The AUR package base is `caelestia-webapps`. Only `PKGBUILD` and `.SRCINFO`
belong in the external AUR Git repository.

Before every AUR update:

1. update `pkgver`, `pkgrel`, release URL and `sha256sums` in `PKGBUILD`;
2. run `makepkg --printsrcinfo > .SRCINFO`;
3. run `makepkg --cleanbuild --force` and inspect the package;
4. run `namcap PKGBUILD` and `namcap` on the built package;
5. copy only `PKGBUILD` and `.SRCINFO` to the AUR checkout;
6. review the AUR diff before committing and pushing.

New AUR accounts require registration at `https://aur.archlinux.org/register`
and a dedicated SSH key registered in the account profile. Do not reuse or
commit the private key.
