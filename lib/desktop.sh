#!/usr/bin/env bash

DESKTOP_CHANGED=false

install_desktop_entry() {
    mkdir -p "$APPLICATIONS_DIR" || die "Applications-Verzeichnis konnte nicht erstellt werden."
    if render_template_if_changed "$TEMPLATE_DIR/desktop.desktop.tpl" "$DESKTOP_FILE" 644 "Desktop-Datei"; then
        DESKTOP_CHANGED=true
    fi
    verify_file "$DESKTOP_FILE"
    verify_contains "$DESKTOP_FILE" 'StartupWMClass='"$WINDOW_CLASS"
    verify_contains "$DESKTOP_FILE" 'Exec='"$LAUNCHER"

    if command -v desktop-file-validate >/dev/null 2>&1; then
        desktop-file-validate "$DESKTOP_FILE" || die "desktop-file-validate meldet einen Fehler."
        ok "Desktop-Datei ist syntaktisch gültig"
    else
        warn "desktop-file-validate fehlt (optional: sudo pacman -S desktop-file-utils)."
    fi
}

update_desktop_database_safe() {
    if [[ "$DESKTOP_CHANGED" != true ]]; then
        info "Desktop-Datei unverändert; Desktop-Datenbank muss nicht aktualisiert werden"
        return 0
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$APPLICATIONS_DIR" || die "update-desktop-database ist fehlgeschlagen."
        ok "Desktop-Datenbank aktualisiert"
    else
        warn "update-desktop-database nicht vorhanden; Caelestia sollte den Eintrag trotzdem erkennen."
    fi
}
