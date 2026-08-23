#!/usr/bin/env bash
CATALOG_FILE="${CATALOG_FILE:-$DATA_ROOT/catalog.json}"
APPLET_REGISTRY_FILE="${APPLET_REGISTRY_FILE:-$DATA_ROOT/applet-registry.json}"

generate_catalog() {
    require_command python3 "sudo pacman -S python"
    mkdir -p "$DATA_ROOT" || die "WebApps-Datenverzeichnis konnte nicht erstellt werden: $DATA_ROOT"

    local stage catalog_stage registry_stage catalog_original
    local catalog_existed=false
    stage="$(mktemp -d "$DATA_ROOT/.runtime-metadata.XXXXXX")" || die "Temporäres Runtime-Metadatenverzeichnis konnte nicht erstellt werden."
    catalog_stage="$stage/catalog.json"
    registry_stage="$stage/applet-registry.json"
    catalog_original="$stage/catalog.original.json"

    # Build and validate the complete pair before replacing either live file.
    if ! python3 "$ROOT_DIR/scripts/generate_catalog.py" "$APP_DEF_DIR" "$USER_APP_DEF_DIR" "$DATA_ROOT" "$catalog_stage"; then
        rm -rf -- "$stage"
        die "Web-App-Katalog konnte nicht erzeugt werden."
    fi
    if ! python3 "$ROOT_DIR/scripts/validate_catalog.py" "$catalog_stage"; then
        rm -rf -- "$stage"
        die "Web-App-Katalog ist ungültig."
    fi
    if ! python3 "$ROOT_DIR/scripts/generate_applet_registry.py" "$catalog_stage" "$registry_stage"; then
        rm -rf -- "$stage"
        die "Applet Registry konnte nicht erzeugt werden."
    fi
    if ! python3 "$ROOT_DIR/scripts/validate_applet_registry.py" "$catalog_stage" "$registry_stage"; then
        rm -rf -- "$stage"
        die "Applet Registry ist inkonsistent zum Katalog."
    fi

    # Commit the validated pair transactionally while the caller owns the
    # global mutation lock. If the second replacement fails, restore the first
    # file atomically so the previous live pair remains authoritative.
    if [[ -f "$CATALOG_FILE" ]]; then
        cp -- "$CATALOG_FILE" "$catalog_original" || { rm -rf -- "$stage"; die "Bestehender Web-App-Katalog konnte nicht gesichert werden."; }
        catalog_existed=true
    fi
    atomic_replace_file "$catalog_stage" "$CATALOG_FILE" 644 || { rm -rf -- "$stage"; die "Web-App-Katalog konnte nicht übernommen werden."; }
    if ! atomic_replace_file "$registry_stage" "$APPLET_REGISTRY_FILE" 644; then
        if [[ "$catalog_existed" == true ]]; then
            atomic_replace_file "$catalog_original" "$CATALOG_FILE" 644 || { rm -rf -- "$stage"; die "Applet Registry konnte nicht übernommen und der Web-App-Katalog nicht zurückgesetzt werden."; }
        else
            rm -f -- "$CATALOG_FILE"
        fi
        # The registry replacement itself never touches the live file before
        # its final rename. Its original therefore remains in place.
        rm -rf -- "$stage"
        die "Applet Registry konnte nicht übernommen werden; der Web-App-Katalog wurde zurückgesetzt."
    fi
    rm -rf -- "$stage"

    verify_file "$CATALOG_FILE"
    verify_contains "$CATALOG_FILE" '"schemaVersion": 2'
    verify_file "$APPLET_REGISTRY_FILE"
    verify_contains "$APPLET_REGISTRY_FILE" '"schemaVersion": 1'
    ok "Web-App-Katalog aktualisiert: $CATALOG_FILE"
    ok "Applet Registry aktualisiert: $APPLET_REGISTRY_FILE"
}
