#!/usr/bin/env bash

# Transactional Hyprland integration. All edits are prepared on temporary
# copies, validated, then committed once. Existing user/native entries are
# never overwritten merely to satisfy WebApp defaults.

# shellcheck source=lib/hyprland_live.sh
source "$ROOT_DIR/lib/hyprland_live.sh"

_hypr_report() {
    local line kind message
    while IFS= read -r line; do
        kind="${line%%|*}"; message="${line#*|}"
        case "$kind" in
            OK) ok "$message" ;;
            WARN) warn "$message" ;;
            INFO) info "$message" ;;
            *) [[ -n "$line" ]] && echo "$line" ;;
        esac
    done
}

_hypr_validate_tmp() {
    local file="$1" label="$2"
    [[ -s "$file" ]] || die "Temporäre $label ist leer."
    if command -v luac >/dev/null 2>&1; then
        luac -p "$file" || die "Temporäre $label enthält ungültige Lua-Syntax."
    fi
}

_hypr_restore_originals() {
    local orig_rules="$1" orig_keys="$2" rules_changed="$3" keys_changed="$4"
    [[ "$rules_changed" == true ]] && cp -- "$orig_rules" "$HYPR_RULES_FILE" 2>/dev/null || true
    [[ "$keys_changed" == true && -f "$orig_keys" ]] && cp -- "$orig_keys" "$HYPR_KEYBINDS_FILE" 2>/dev/null || true
}

install_hyprland_rule() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        warn "hyprctl wurde nicht gefunden; Caelestia-Lua-Regeln werden übersprungen."
        return 0
    fi
    [[ -f "$HYPR_RULES_FILE" ]] || {
        warn "Keine Caelestia rules.lua gefunden: $HYPR_RULES_FILE"
        return 0
    }
    require_command python3 "sudo pacman -S python"

    local tx orig_rules orig_keys tmp_rules tmp_keys report rules_changed=false keys_changed=false
    local lua_live=false shared_runtime_created=false runtime_ok=true
    tx="$(mktemp -d)" || die "Temporäres Hyprland-Arbeitsverzeichnis konnte nicht erstellt werden."
    orig_rules="$tx/rules.original.lua"; tmp_rules="$tx/rules.lua"
    cp -- "$HYPR_RULES_FILE" "$orig_rules" || { rm -rf "$tx"; die "rules.lua konnte nicht gesichert werden."; }
    cp -- "$orig_rules" "$tmp_rules"

    if [[ "${HYPR_SHARED_OWNER:-}" == "caelestia-webapps" \
       && -n "${HYPR_SHARED_LOCAL_DECL:-}" \
       ]] && ! grep -Fq -- "$HYPR_SHARED_LOCAL_DECL" "$orig_rules"; then
        shared_runtime_created=true
    fi

    orig_keys="$tx/keybinds.original.lua"; tmp_keys="$tx/keybinds.lua"
    if [[ -f "$HYPR_KEYBINDS_FILE" ]]; then
        cp -- "$HYPR_KEYBINDS_FILE" "$orig_keys" || { rm -rf "$tx"; die "keybinds.lua konnte nicht gesichert werden."; }
        cp -- "$orig_keys" "$tmp_keys"
    else
        tmp_keys=""
    fi

    if ! report="$(python3 "$ROOT_DIR/scripts/hyprland_prepare.py" \
        --rules "$tmp_rules" \
        ${tmp_keys:+--keybinds "$tmp_keys"} \
        --category "${APP_CATALOG_CATEGORY:-other}" \
        --class-name "$WINDOW_CLASS" \
        --app-name "$APP_NAME" \
        --use-opaque "$USE_OPAQUE_TAG" 2>&1)"; then
        echo "$report"
        rm -rf "$tx"
        die "Hyprland-Konflikt erkannt. Keine Live-Konfigurationsdatei wurde verändert."
    fi
    printf '%s\n' "$report" | _hypr_report

    cmp -s -- "$orig_rules" "$tmp_rules" || rules_changed=true
    if [[ -n "$tmp_keys" ]]; then cmp -s -- "$orig_keys" "$tmp_keys" || keys_changed=true; fi

    if [[ "$rules_changed" != true && "$keys_changed" != true ]]; then
        rm -rf "$tx"
        info "Hyprland-Regeln bereits aktuell; Reload wird übersprungen"
        return 0
    fi

    _hypr_validate_tmp "$tmp_rules" "rules.lua"
    [[ "$keys_changed" == true ]] && _hypr_validate_tmp "$tmp_keys" "keybinds.lua"
    ok "Temporäre Hyprland-Konfiguration vollständig geprüft"

    # Abort if another process/user edited the files while we prepared them.
    cmp -s -- "$orig_rules" "$HYPR_RULES_FILE" || { rm -rf "$tx"; die "rules.lua wurde während der Installation extern verändert; Commit abgebrochen."; }
    if [[ -f "$orig_keys" ]]; then
        cmp -s -- "$orig_keys" "$HYPR_KEYBINDS_FILE" || { rm -rf "$tx"; die "keybinds.lua wurde während der Installation extern verändert; Commit abgebrochen."; }
    fi

    if hypr_lua_live_begin; then
        lua_live=true
        info "Hyprland-Lua-Regeln werden ohne vollständigen Konfigurationsreload aktiviert"
    fi

    [[ "$rules_changed" == true ]] && backup_file "$HYPR_RULES_FILE"
    [[ "$keys_changed" == true ]] && backup_file "$HYPR_KEYBINDS_FILE"

    if [[ "$rules_changed" == true ]]; then
        if ! cp -- "$tmp_rules" "$HYPR_RULES_FILE"; then
            [[ "$lua_live" == true ]] && hypr_lua_live_finish || true
            rm -rf "$tx"
            die "rules.lua konnte nicht atomar übernommen werden."
        fi
        ok "rules.lua aktualisiert"
    fi
    if [[ "$keys_changed" == true ]]; then
        if ! cp -- "$tmp_keys" "$HYPR_KEYBINDS_FILE"; then
            _hypr_restore_originals "$orig_rules" "$orig_keys" "$rules_changed" "$keys_changed"
            [[ "$lua_live" == true ]] && hypr_lua_live_finish || true
            rm -rf "$tx"
            die "keybinds.lua konnte nicht übernommen werden; rules.lua wurde zurückgesetzt."
        fi
        ok "keybinds.lua aktualisiert"
    fi

    if [[ "$lua_live" == true ]]; then
        hypr_lua_apply_app_rules || runtime_ok=false
        if [[ "$runtime_ok" == true && "$shared_runtime_created" == true ]]; then
            hypr_lua_apply_project_shared_runtime || runtime_ok=false
        fi
        if [[ "$runtime_ok" != true ]]; then
            hypr_lua_disable_app_rules
            [[ "$shared_runtime_created" == true ]] && hypr_lua_disable_project_shared_runtime
            _hypr_restore_originals "$orig_rules" "$orig_keys" "$rules_changed" "$keys_changed"
            hypr_lua_live_finish || true
            rm -rf "$tx"
            die "Hyprland-Laufzeitregeln konnten nicht aktiviert werden; ursprüngliche Konfiguration wurde wiederhergestellt."
        fi
        if ! hypr_lua_live_finish; then
            rm -rf "$tx"
            die "Hyprland-Autoreload konnte nicht sicher wiederhergestellt werden."
        fi
        rm -rf "$tx"
        ok "Hyprland-Regeln ohne Monitor-Reload aktiviert"
        return 0
    fi

    info "Hyprland-Konfiguration wird neu geladen"
    local reload_output errors
    if ! reload_output="$(hyprctl reload 2>&1)"; then
        echo "$reload_output"
        _hypr_restore_originals "$orig_rules" "$orig_keys" "$rules_changed" "$keys_changed"
        hyprctl reload >/dev/null 2>&1 || true
        rm -rf "$tx"
        die "hyprctl reload ist fehlgeschlagen; ursprüngliche Konfiguration wurde wiederhergestellt."
    fi
    errors="$(hyprctl configerrors 2>&1 || true)"
    if [[ -n "$errors" && "$errors" != "no errors" && "$errors" != *"No errors"* ]]; then
        echo "$errors"
        _hypr_restore_originals "$orig_rules" "$orig_keys" "$rules_changed" "$keys_changed"
        hyprctl reload >/dev/null 2>&1 || true
        rm -rf "$tx"
        die "Hyprland meldet Konfigurationsfehler; ursprüngliche Konfiguration wurde wiederhergestellt."
    fi
    rm -rf "$tx"
    ok "Hyprland meldet keine Konfigurationsfehler"
}
