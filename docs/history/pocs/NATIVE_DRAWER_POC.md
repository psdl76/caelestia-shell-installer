# Native Caelestia Drawer PoC

This is deliberately **not** a new WebApps release and does not replace v0.3.27.

The PoC temporarily swaps only `modules/sidebar/Content.qml`. Caelestia's existing
Sidebar Wrapper, Drawers window, `PanelBg`, `BlobRect`, deformation matrix, animation
tokens and layer-shell window stay untouched. Therefore opening the sidebar exercises
the real native Caelestia drawer/blob animation rather than imitating it.

## Install

```bash
./native-drawer-poc.sh install
caelestia shell -k && caelestia shell -d
caelestia shell drawers toggle sidebar
```

## Restore

```bash
./native-drawer-poc.sh restore
caelestia shell -k && caelestia shell -d
```

The original Sidebar Content is backed up under
`~/.local/state/caelestia-webapps/native-drawer-poc/`.
