#!/usr/bin/env bash

ICON_CHANGED=false

_install_local_icon_fallback() {
    local local_file="${ICON_LOCAL_FILE:-}"
    [[ -n "$local_file" && -f "$local_file" ]] || return 1
    grep -qi '<svg' "$local_file" || die "Lokales Fallback-Icon ist kein SVG: $local_file"
    info "Lokales Icon-Fallback: $local_file"
    cp "$local_file" "$1" || die "Lokales Fallback-Icon konnte nicht kopiert werden."
    return 0
}

install_icon() {
    mkdir -p "$ICON_DIR" || die "Icon-Verzeichnis konnte nicht erstellt werden."
    local tmp remote_ok=false
    tmp="$(mktemp)" || die "Temporäre Icon-Datei konnte nicht erstellt werden."

    if [[ -n "${ICON_URL:-}" ]]; then
        require_command curl "sudo pacman -S curl"
        info "Icon-Quelle: $ICON_URL"
        if curl --fail --location --silent --show-error --connect-timeout 15 --max-time 60 \
            "$ICON_URL" --output "$tmp" && [[ -s "$tmp" ]] && grep -qi '<svg' "$tmp"; then
            remote_ok=true
        else
            warn "Remote-Icon nicht verfügbar oder ungültig; lokales Fallback wird versucht."
            : > "$tmp"
        fi
    fi

    if [[ "$remote_ok" != true ]]; then
        if ! _install_local_icon_fallback "$tmp"; then
            rm -f "$tmp"
            if [[ -n "${ICON_URL:-}" ]]; then
                die "Download des Icons fehlgeschlagen und kein lokales Fallback ist verfügbar."
            else
                die "Kein gültiges Icon konfiguriert (ICON_URL/ICON_LOCAL_FILE)."
            fi
        fi
    fi

    [[ -s "$tmp" ]] || { rm -f "$tmp"; die "Das Icon ist leer."; }
    grep -qi '<svg' "$tmp" || { rm -f "$tmp"; die "Die Icon-Datei scheint kein SVG zu sein."; }

    if install_file_if_changed "$tmp" "$ICON_FILE" 644 "$APP_NAME-Icon"; then
        ICON_CHANGED=true
    else
        rm -f "$tmp"
    fi

    verify_file "$ICON_FILE"
    verify_contains "$ICON_FILE" '<svg'
    ok "$APP_NAME-Icon installiert"
}

update_icon_cache() {
    if [[ "$ICON_CHANGED" != true ]]; then
        info "Icon unverändert; GTK Icon-Cache muss nicht aktualisiert werden"
        return 0
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if gtk-update-icon-cache --force --ignore-theme-index "$ICON_ROOT"; then
            ok "GTK Icon-Cache aktualisiert"
        else
            warn "GTK Icon-Cache konnte nicht aktualisiert werden; das Icon ist dennoch installiert."
        fi
    else
        warn "gtk-update-icon-cache nicht gefunden; wird übersprungen."
    fi
}
