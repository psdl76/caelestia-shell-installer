#!/usr/bin/env bash

# Global cross-process lock for all state/config mutations. Different apps still
# share catalog.json, Hyprland config and desktop/icon caches, so a per-app lock
# would not be sufficient.
LOCK_BUSY_EXIT=75
LOCK_TIMEOUT_SECONDS="${CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS:-2}"

_lock_root() {
    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
        printf '%s/caelestia-webapps\n' "$XDG_RUNTIME_DIR"
    else
        printf '%s/.local/state/caelestia-webapps/locks\n' "$HOME"
    fi
}

mutation_lock_path() {
    printf '%s/mutation.lock\n' "$(_lock_root)"
}

_acquire_lock_common() {
    local mode="$1" label="$2" dir file
    [[ "${CAELESTIA_WEBAPPS_LOCK_HELD:-}" == "exclusive" ]] && return 0
    if [[ "$mode" == "shared" && "${CAELESTIA_WEBAPPS_LOCK_HELD:-}" == "shared" ]]; then
        return 0
    fi
    command -v flock >/dev/null 2>&1 || {
        echo "FEHLER: flock fehlt (util-linux)." >&2
        exit 1
    }
    dir="$(_lock_root)"
    mkdir -p "$dir" || { echo "FEHLER: Lock-Verzeichnis konnte nicht erstellt werden: $dir" >&2; exit 1; }
    file="$(mutation_lock_path)"
    exec 9>"$file"
    if [[ "$mode" == "exclusive" ]]; then
        if ! flock -x -w "$LOCK_TIMEOUT_SECONDS" 9; then
            echo "CAELESTIA_WEBAPPS_LOCK_BUSY: $label" >&2
            exit "$LOCK_BUSY_EXIT"
        fi
        export CAELESTIA_WEBAPPS_LOCK_HELD=exclusive
    else
        if ! flock -s -w "$LOCK_TIMEOUT_SECONDS" 9; then
            echo "CAELESTIA_WEBAPPS_LOCK_BUSY: $label" >&2
            exit "$LOCK_BUSY_EXIT"
        fi
        export CAELESTIA_WEBAPPS_LOCK_HELD=shared
    fi
}

acquire_mutation_lock() { _acquire_lock_common exclusive "${1:-mutation}"; }
acquire_read_lock() { _acquire_lock_common shared "${1:-read}"; }
