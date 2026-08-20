#!/usr/bin/env bash

USER_APP_DEF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-webapps/apps"

find_app_definition() {
    local id="$1"
    if [[ -f "$USER_APP_DEF_DIR/$id.conf" ]]; then
        printf '%s\n' "$USER_APP_DEF_DIR/$id.conf"
        return 0
    fi
    if [[ -f "$APP_DEF_DIR/$id.conf" ]]; then
        printf '%s\n' "$APP_DEF_DIR/$id.conf"
        return 0
    fi
    return 1
}

app_definition_source() {
    local path="$1"
    if [[ "$path" == "$USER_APP_DEF_DIR/"* ]]; then
        printf 'user\n'
    else
        printf 'builtin\n'
    fi
}

list_app_ids() {
    local f
    {
        shopt -s nullglob
        for f in "$APP_DEF_DIR"/*.conf "$USER_APP_DEF_DIR"/*.conf; do
            basename "$f" .conf
        done
    } | sort -u
}
