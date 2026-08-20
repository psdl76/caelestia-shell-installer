#!/usr/bin/env bash

# Hyprland 0.55+ Lua configurations reload the complete configuration when an
# imported Lua file is saved. On some monitor stacks that causes a real modeset
# and a visible black frame. Persist validated changes with autoreload suspended
# and apply only the app-specific rules through Hyprland's public Lua API.

HYPR_LUA_LIVE_ACTIVE=false
HYPR_LUA_AUTORELOAD_WAS_DISABLED=false

hypr_lua_live_supported() {
    local system_info
    system_info="$(hyprctl systeminfo 2>/dev/null)" || return 1
    grep -Fq 'configProvider: lua' <<< "$system_info" || return 1
    hyprctl getoption misc:disable_autoreload -j >/dev/null 2>&1 || return 1
}

hypr_lua_live_begin() {
    HYPR_LUA_LIVE_ACTIVE=false
    HYPR_LUA_AUTORELOAD_WAS_DISABLED=false
    hypr_lua_live_supported || return 1

    local option_json
    option_json="$(hyprctl getoption misc:disable_autoreload -j 2>/dev/null)" || return 1
    if python3 -c 'import json,sys; raise SystemExit(0 if json.load(sys.stdin).get("bool") is True else 1)' <<< "$option_json"; then
        HYPR_LUA_AUTORELOAD_WAS_DISABLED=true
    fi
    # hl.config schedules property refreshes for the next event-loop turn.
    # Force that refresh to run inside this IPC call so the inotify watches are
    # actually gone before the caller writes an imported Lua file.
    hypr_lua_set_autoreload_disabled true || return 1
    HYPR_LUA_LIVE_ACTIVE=true
}

hypr_lua_live_finish() {
    [[ "$HYPR_LUA_LIVE_ACTIVE" == true ]] || return 0
    local restore_value=false
    [[ "$HYPR_LUA_AUTORELOAD_WAS_DISABLED" == true ]] && restore_value=true
    if ! hypr_lua_set_autoreload_disabled "$restore_value"; then
        warn "Hyprland-Autoreload konnte nicht auf den vorherigen Wert zurückgesetzt werden."
        return 1
    fi
    HYPR_LUA_LIVE_ACTIVE=false
}

hypr_lua_set_autoreload_disabled() {
    local value="$1"
    hypr_lua_eval \
        "hl.config({ misc = { disable_autoreload = $value } }); hl.exec_scheduled_prop_refresh_immediately()" \
        "Hyprland-Autoreload-Umschaltung"
}

hypr_runtime_tag_name() {
    printf '%s\n' "${1%_tag}"
}

hypr_runtime_rule_name() {
    printf 'caelestia-webapps-%s-%s\n' "$APP_ID" "$1"
}

hypr_lua_eval() {
    local expression="$1" label="$2" output
    if ! output="$(hyprctl eval "$expression" 2>&1)"; then
        [[ -n "$output" ]] && echo "$output"
        warn "$label konnte nicht ohne vollständigen Hyprland-Reload aktiviert werden."
        return 1
    fi
}

hypr_lua_apply_tag_rule() {
    local tag_name="$1" rule_name
    rule_name="$(hypr_runtime_rule_name "$tag_name")"
    hypr_lua_eval \
        "hl.window_rule({ name = \"$rule_name\", match = { class = \"$WINDOW_CLASS\" }, tag = \"+$tag_name\" })" \
        "Hyprland-Regel $rule_name"
}

hypr_lua_disable_named_rule() {
    hyprctl keyword "windowrule[$1]:enable" false >/dev/null 2>&1 || true
}

hypr_lua_disable_app_rules() {
    local tag_name
    hypr_lua_disable_named_rule "$(hypr_runtime_rule_name opaque)"
    if [[ -n "${HYPR_SHARED_TAG:-}" ]]; then
        tag_name="$(hypr_runtime_tag_name "$HYPR_SHARED_TAG")"
        hypr_lua_disable_named_rule "$(hypr_runtime_rule_name "$tag_name")"
    fi
}

hypr_lua_apply_app_rules() {
    if [[ "${USE_OPAQUE_TAG:-false}" == true ]]; then
        hypr_lua_apply_tag_rule opaque || return 1
    fi
    if [[ -n "${HYPR_SHARED_TAG:-}" ]]; then
        hypr_lua_apply_tag_rule "$(hypr_runtime_tag_name "$HYPR_SHARED_TAG")" || return 1
    fi
}

hypr_lua_apply_project_shared_runtime() {
    [[ "${HYPR_SHARED_OWNER:-}" == "caelestia-webapps" ]] || return 0
    local tag_name rule_name
    tag_name="$(hypr_runtime_tag_name "$HYPR_SHARED_TAG")"
    rule_name="caelestia-webapps-shared-$tag_name"
    hypr_lua_eval \
        "hl.window_rule({ name = \"$rule_name\", match = { tag = \"$tag_name\" }, workspace = \"special:${HYPR_SHARED_WORKSPACE}\", opaque = true, idle_inhibit = \"always\" })" \
        "Gemeinsame Hyprland-Regel $rule_name" || return 1
    if [[ -n "${HYPR_SHARED_KEYBIND:-}" ]]; then
        hypr_lua_eval \
            "hl.bind(\"SUPER + Y\", hl.dsp.workspace.toggle_special(\"${HYPR_SHARED_WORKSPACE}\"))" \
            "Streaming-Workspace-Tastenkürzel" || return 1
    fi
}

hypr_lua_disable_project_shared_runtime() {
    [[ "${HYPR_SHARED_OWNER:-}" == "caelestia-webapps" ]] || return 0
    local tag_name
    tag_name="$(hypr_runtime_tag_name "$HYPR_SHARED_TAG")"
    hypr_lua_disable_named_rule "caelestia-webapps-shared-$tag_name"
    if [[ -n "${HYPR_SHARED_KEYBIND:-}" ]]; then
        hypr_lua_eval "hl.unbind(\"SUPER + Y\")" "Streaming-Workspace-Tastenkürzel" || true
    fi
}
