#!/usr/bin/env bash

CATEGORY_SCHEMA_FILE="$ROOT_DIR/config/categories.json"
CATEGORY_SCHEMA_TOOL="$ROOT_DIR/scripts/app_schema.py"

[[ -f "$CATEGORY_SCHEMA_FILE" ]] || { echo "FEHLER: Kategorie-Schema fehlt: $CATEGORY_SCHEMA_FILE" >&2; return 1; }
[[ -f "$CATEGORY_SCHEMA_TOOL" ]] || { echo "FEHLER: Kategorie-Schema-Tool fehlt: $CATEGORY_SCHEMA_TOOL" >&2; return 1; }
command -v python3 >/dev/null 2>&1 || { echo "FEHLER: python3 wird für das App-Schema benötigt." >&2; return 1; }

# Load the JSON schema once per process. apply_app_category_defaults itself is
# pure Bash and therefore cheap even while scanning every app definition.
_schema_assignments="$(python3 "$CATEGORY_SCHEMA_TOOL" shell-all "$CATEGORY_SCHEMA_FILE")" || return 1
eval "$_schema_assignments"
unset _schema_assignments

category_exists() {
    local wanted="$1" category
    for category in "${APP_CATALOG_CATEGORIES[@]}"; do
        [[ "$category" == "$wanted" ]] && return 0
    done
    return 1
}

apply_app_category_defaults() {
    local category="${APP_CATALOG_CATEGORY:-}" extra
    [[ -n "$category" ]] || die "APP_CATALOG_CATEGORY fehlt in der App-Definition."
    category_exists "$category" || die "Unbekannte APP_CATALOG_CATEGORY: $category. Erlaubt: ${APP_CATALOG_CATEGORIES[*]}"
    if [[ -n "${APP_CATALOG_CATEGORIES_LIST:-}" ]]; then
        IFS=';' read -r -a _app_catalog_categories <<< "$APP_CATALOG_CATEGORIES_LIST"
        for extra in "${_app_catalog_categories[@]}"; do
            [[ -z "$extra" ]] && continue
            category_exists "$extra" || die "Unbekannte APP_CATALOG_CATEGORIES_LIST-Kategorie: $extra"
        done
        unset _app_catalog_categories
    fi

    APPLET_VISIBLE="${CATEGORY_APPLET_VISIBLE[$category]}"
    APPLET_SHOW_BADGE="${CATEGORY_APPLET_SHOW_BADGE[$category]}"
    APPLET_NOTIFICATION_PREVIEW="${CATEGORY_APPLET_NOTIFICATION_PREVIEW[$category]}"
    HYPR_SHARED_TAG="${CATEGORY_HYPR_SHARED_TAG[$category]}"
    HYPR_SHARED_OWNER="${CATEGORY_HYPR_SHARED_OWNER[$category]}"
    HYPR_SHARED_WORKSPACE="${CATEGORY_HYPR_SHARED_WORKSPACE[$category]}"
    HYPR_SHARED_LOCAL_DECL="${CATEGORY_HYPR_SHARED_LOCAL_DECL[$category]}"
    HYPR_SHARED_RULE_MARKER="${CATEGORY_HYPR_SHARED_RULE_MARKER[$category]}"
    HYPR_SHARED_CREATE_TAG="${CATEGORY_HYPR_SHARED_CREATE_TAG[$category]}"
    HYPR_SHARED_KEYBIND="${CATEGORY_HYPR_SHARED_KEYBIND[$category]}"
}

validate_app_schema_source() {
    local conf="$1" bad
    bad="$(grep -En '^(APPLET_VISIBLE|APPLET_SHOW_BADGE|APPLET_NOTIFICATION_PREVIEW|HYPR_SHARED_[A-Z0-9_]+)=' "$conf" || true)"
    if [[ -n "$bad" ]]; then
        die "App-Definition $(basename "$conf") setzt zentral verwaltete Kategorie-Felder:\n$bad\nDiese Werte gehören nach config/categories.json."
    fi
}

validate_app_definition() {
    local var
    for var in APP_ID APP_NAME APP_GENERIC_NAME APP_COMMENT APP_URL APP_CATEGORIES APP_KEYWORDS \
               MOZ_APP_REMOTINGNAME WINDOW_CLASS ICON_NAME USE_OPAQUE_TAG APP_CATALOG_CATEGORY NOTIFICATION_MATCH; do
        [[ -n "${!var:-}" ]] || die "App-Definition enthält keinen Wert für $var"
    done

    [[ "$APP_ID" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || die "Ungültige APP_ID: $APP_ID"
    [[ "$MOZ_APP_REMOTINGNAME" =~ ^[A-Za-z0-9._-]+$ ]] || die "Ungültiger MOZ_APP_REMOTINGNAME: $MOZ_APP_REMOTINGNAME"
    [[ "$WINDOW_CLASS" =~ ^[A-Za-z0-9._-]+$ ]] || die "Ungültige WINDOW_CLASS: $WINDOW_CLASS"
    if [[ -n "${BROWSER_BRIDGE_PORT:-}" ]]; then
        [[ "$BROWSER_BRIDGE_PORT" =~ ^[0-9]+$ ]] || die "BROWSER_BRIDGE_PORT muss numerisch sein."
        (( BROWSER_BRIDGE_PORT >= 1024 && BROWSER_BRIDGE_PORT <= 65535 )) || die "BROWSER_BRIDGE_PORT muss zwischen 1024 und 65535 liegen."
    fi
    [[ "$ICON_NAME" =~ ^[A-Za-z0-9._-]+$ ]] || die "Ungültiger ICON_NAME: $ICON_NAME"
    [[ "$APP_URL" == http://* || "$APP_URL" == https://* ]] || die "APP_URL muss http:// oder https:// verwenden."
    [[ "$APP_CATEGORIES" == *';' ]] || die "APP_CATEGORIES muss mit einem Semikolon enden."
    [[ "$APP_KEYWORDS" == *';' ]] || die "APP_KEYWORDS muss mit einem Semikolon enden."
    [[ -n "${ICON_URL:-}" || -n "${ICON_LOCAL_FILE:-}" ]] || die "App-Definition braucht ICON_URL oder ICON_LOCAL_FILE."
    if [[ -n "${ICON_LOCAL_FILE:-}" && ! -f "$ICON_LOCAL_FILE" ]]; then
        die "Lokales Icon-Fallback fehlt: $ICON_LOCAL_FILE"
    fi
    [[ "$USE_OPAQUE_TAG" == "true" || "$USE_OPAQUE_TAG" == "false" ]] || die "USE_OPAQUE_TAG muss true oder false sein."
    for var in APPLET_VISIBLE APPLET_SHOW_BADGE APPLET_NOTIFICATION_PREVIEW; do
        [[ "${!var}" == "true" || "${!var}" == "false" ]] || die "$var muss true oder false sein (Kategorie: $APP_CATALOG_CATEGORY)."
    done
    ok "App-Definition validiert: $APP_NAME ($APP_ID) · Kategorie: $APP_CATALOG_CATEGORY"
}
