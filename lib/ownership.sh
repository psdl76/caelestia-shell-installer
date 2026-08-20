#!/usr/bin/env bash

# Ownership model:
# - built-in app definitions live in $APP_DEF_DIR and are package-owned
# - user app definitions live in $USER_APP_DEF_DIR and are user-owned
# - user-owned definitions must never be overwritten or deleted by repair/update

app_source_for_id() {
    local id="$1"
    if [[ -f "$USER_APP_DEF_DIR/$id.conf" ]]; then
        printf 'user\n'
    elif [[ -f "$APP_DEF_DIR/$id.conf" ]]; then
        printf 'builtin\n'
    else
        return 1
    fi
}

is_user_app_id() {
    [[ "$(app_source_for_id "$1" 2>/dev/null || true)" == "user" ]]
}

is_builtin_app_id() {
    [[ "$(app_source_for_id "$1" 2>/dev/null || true)" == "builtin" ]]
}

assert_no_shadowing() {
    local f id
    shopt -s nullglob
    for f in "$USER_APP_DEF_DIR"/*.conf; do
        id="$(basename "$f" .conf)"
        if [[ -f "$APP_DEF_DIR/$id.conf" ]]; then
            printf 'User-App-ID überschneidet sich mit Built-in: %s\n' "$id" >&2
            return 1
        fi
    done
}
