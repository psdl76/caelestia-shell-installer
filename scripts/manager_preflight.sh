#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

emit() {
    local stage="$1" label="$2" detail="$3" progress="$4" state="${5:-running}"
    # All values emitted here are project-owned static strings or sanitized IDs.
    printf '{"stage":"%s","label":"%s","detail":"%s","progress":%s,"state":"%s"}\n' \
        "$stage" "$label" "$detail" "$progress" "$state"
}

emit "theme" "Caelestia Theme" "Farbschema wird übernommen" "0.06"
if command -v python3 >/dev/null 2>&1; then
    "$ROOT_DIR/scripts/caelestia_theme_bridge.py" >/dev/null 2>&1 || true
fi
emit "theme" "Caelestia Theme" "Farbschema bereit" "0.14" "done"

emit "icons" "WebApp Icons" "Lokaler Icon-Cache wird geprüft" "0.16"
CAELESTIA_WEBAPPS_PROGRESS=1 "$ROOT_DIR/scripts/prepare_store_icons.sh" || true

emit "catalog" "WebApp Katalog" "Katalogdaten werden aktualisiert" "0.86"
if ! "$ROOT_DIR/bin/caelestia-webapps" refresh >/dev/null; then
    emit "error" "Start fehlgeschlagen" "WebApps-Katalog konnte nicht aktualisiert werden" "1.0" "error"
    exit 1
fi

emit "manager" "WebApps Manager" "Oberfläche wird geöffnet" "0.97"
emit "ready" "WebApps Manager" "Bereit" "1.0" "done"
