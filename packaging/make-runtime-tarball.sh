#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-$(<"$ROOT/VERSION")}"
OUT="${2:-$ROOT/dist}"
NAME="caelestia-webapps-$VERSION"
mkdir -p "$OUT"
TMP="$(mktemp -d)"
GATE_TMP=""
trap 'rm -rf -- "$TMP" ${GATE_TMP:+"$GATE_TMP"}' EXIT

# Phase 16.2 packaging gate: never ship a broken built-in catalog contract.
echo "[gate] validating built-in catalog schema contract" >&2
python3 "$ROOT/scripts/validate_definitions.py" "$ROOT" >/dev/null
GATE_TMP="$(mktemp -d)"
mkdir -p "$GATE_TMP/data" "$GATE_TMP/user"
python3 "$ROOT/scripts/generate_catalog.py" "$ROOT/apps" "$GATE_TMP/user" "$GATE_TMP/data" "$GATE_TMP/catalog.json"
python3 "$ROOT/scripts/validate_catalog.py" "$GATE_TMP/catalog.json"
echo "[gate] catalog contract PASS" >&2
python3 "$ROOT/scripts/generate_applet_registry.py" "$GATE_TMP/catalog.json" "$GATE_TMP/applet-registry.json"
python3 "$ROOT/scripts/validate_applet_registry.py" "$GATE_TMP/catalog.json" "$GATE_TMP/applet-registry.json"
echo "[gate] applet registry contract PASS" >&2
python3 "$ROOT/scripts/validate_applet_implementations.py" "$GATE_TMP/applet-registry.json" "$ROOT/integrations/caelestia/plugin/manifest.json" "$ROOT/integrations/caelestia/plugin" >/dev/null
echo "[gate] applet runtime mapping PASS" >&2
python3 "$ROOT/scripts/validate_applet_runtime_sources.py" "$ROOT" >/dev/null
echo "[gate] applet runtime source PASS" >&2
mkdir -p "$TMP/$NAME"
while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    cp -a -- "$ROOT/$entry" "$TMP/$NAME/"
done < "$ROOT/packaging/runtime-entries.txt"
mkdir -p "$TMP/$NAME/packaging/arch/wrappers"
cp -a "$ROOT/packaging/arch/wrappers/." "$TMP/$NAME/packaging/arch/wrappers/"
cp -a "$ROOT/packaging/LICENSE-PENDING.txt" "$TMP/$NAME/packaging/"
cp -a "$ROOT/packaging/caelestia-webapps-manager.desktop" "$TMP/$NAME/packaging/"
tar -C "$TMP" -czf "$OUT/$NAME.tar.gz" "$NAME"
printf '%s\n' "$OUT/$NAME.tar.gz"
