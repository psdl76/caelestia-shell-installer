#!/usr/bin/env bash
CATALOG_FILE="${CATALOG_FILE:-$DATA_ROOT/catalog.json}"
APPLET_REGISTRY_FILE="${APPLET_REGISTRY_FILE:-$DATA_ROOT/applet-registry.json}"

generate_catalog() {
    require_command python3 "sudo pacman -S python"
    mkdir -p "$DATA_ROOT" || die "WebApps-Datenverzeichnis konnte nicht erstellt werden: $DATA_ROOT"

    local stage catalog_stage registry_stage
    stage="$(mktemp -d "$DATA_ROOT/.runtime-metadata.XXXXXX")" || die "Temporäres Runtime-Metadatenverzeichnis konnte nicht erstellt werden."
    catalog_stage="$stage/catalog.json"
    registry_stage="$stage/applet-registry.json"

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

    # Only a fully validated pair is committed. Existing metadata therefore
    # survives generation/validation failures unchanged.
    install -m 644 "$catalog_stage" "$CATALOG_FILE" || { rm -rf -- "$stage"; die "Web-App-Katalog konnte nicht übernommen werden."; }
    install -m 644 "$registry_stage" "$APPLET_REGISTRY_FILE" || { rm -rf -- "$stage"; die "Applet Registry konnte nicht übernommen werden."; }
    rm -rf -- "$stage"

    verify_file "$CATALOG_FILE"
    verify_contains "$CATALOG_FILE" '"schemaVersion": 2'
    verify_file "$APPLET_REGISTRY_FILE"
    verify_contains "$APPLET_REGISTRY_FILE" '"schemaVersion": 1'
    ok "Web-App-Katalog aktualisiert: $CATALOG_FILE"
    ok "Applet Registry aktualisiert: $APPLET_REGISTRY_FILE"
}
