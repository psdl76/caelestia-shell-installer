# Caelestia WebApps branding

`caelestia-webapps.svg` is the canonical, transparent vector master for the
project logo. It is reconstructed from `logo-source.png` using native SVG paths
and gradients; it does not embed the raster source.

The files under `png/` are deterministic launcher-size exports rendered from
the SVG master with librsvg. Regenerate them with:

```bash
for size in 16 24 32 48 64 128 256 512; do
    rsvg-convert -w "$size" -h "$size" \
        -o "png/caelestia-webapps-$size.png" \
        caelestia-webapps.svg
done
```

The transparent raster source is retained as the visual design reference. Do
not replace the SVG with an SVG wrapper that merely embeds this PNG.
