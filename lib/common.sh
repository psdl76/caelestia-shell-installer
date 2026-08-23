#!/usr/bin/env bash

if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; RESET=''
fi

CURRENT_STEP="Initialisierung"
STEP_NUMBER=0
ERROR_FILE=""
ERROR_RECOVERY=""

step() {
    STEP_NUMBER=$((STEP_NUMBER + 1))
    CURRENT_STEP="$1"
    ERROR_FILE=""
    ERROR_RECOVERY=""
    echo
    echo -e "${BLUE}${BOLD}[$STEP_NUMBER] $CURRENT_STEP${RESET}"
    echo "------------------------------------------------------------"
}

ok()   { echo -e "${GREEN}✓ $*${RESET}"; }
info() { echo -e "${CYAN}→ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $*${RESET}"; }

error_context() {
    ERROR_FILE="${1:-}"
    ERROR_RECOVERY="${2:-}"
}

clear_error_context() {
    ERROR_FILE=""
    ERROR_RECOVERY=""
}

_redact_command() {
    local text="$1"
    # Never print likely credentials from a failed command into terminal/logs.
    printf '%s' "$text" | sed -E \
      -e 's/((password|passwd|token|secret|api[_-]?key|authorization)[=:][[:space:]]*)[^[:space:]]+/\1<redacted>/Ig' \
      -e 's/(Bearer[[:space:]]+)[A-Za-z0-9._~+\/-]+/\1<redacted>/Ig'
}

_print_failure_context() {
    [[ -n "${ERROR_FILE:-}" ]] && echo "Datei     : $ERROR_FILE"
    [[ -n "${ERROR_RECOVERY:-}" ]] && echo "Wiederherst.: $ERROR_RECOVERY"
    [[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR:-}" ]] && echo "Backups   : $BACKUP_DIR"
    [[ -n "${LOG_FILE:-}" ]] && echo "Logdatei  : $LOG_FILE"
}

die() {
    local message="$*"
    echo
    echo -e "${RED}${BOLD}✗ VORGANG ABGEBROCHEN${RESET}"
    echo
    echo -e "${RED}Schritt   : $CURRENT_STEP${RESET}"
    echo -e "${RED}Ursache   : $message${RESET}"
    _print_failure_context
    exit 1
}

on_error() {
    local exit_code=$?
    local line_number=${BASH_LINENO[0]:-${LINENO}}
    local command=${BASH_COMMAND:-unbekannt}
    command="$(_redact_command "$command")"
    echo
    echo -e "${RED}${BOLD}✗ UNERWARTETER FEHLER${RESET}"
    echo "Schritt   : $CURRENT_STEP"
    echo "Exit-Code : $exit_code"
    echo "Zeile     : $line_number"
    echo "Kommando  : $command"
    _print_failure_context
    exit "$exit_code"
}

require_command() {
    local cmd="$1"
    local hint="${2:-}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd gefunden: $(command -v "$cmd")"
        return 0
    fi
    [[ -n "$hint" ]] && echo "Installation: $hint"
    die "$cmd fehlt."
}

verify_directory() {
    local dir="$1"
    [[ -d "$dir" ]] || die "Verzeichnis wurde nicht erstellt: $dir"
    [[ -w "$dir" ]] || die "Verzeichnis ist nicht beschreibbar: $dir"
    ok "Verzeichnis geprüft: $dir"
}

verify_file() {
    local file="$1"
    [[ -f "$file" ]] || die "Datei existiert nach Erstellung nicht: $file"
    [[ -s "$file" ]] || die "Datei existiert, ist aber leer: $file"
    ok "Datei geprüft: $file"
}

verify_contains() {
    local file="$1" text="$2"
    grep -Fq -- "$text" "$file" || die "Erwarteter Inhalt fehlt in $file: $text"
    ok "Inhalt geprüft: $text"
}

backup_file() {
    local file="$1"
    [[ -e "$file" ]] || return 0
    mkdir -p "$BACKUP_DIR" || die "Backup-Verzeichnis konnte nicht erstellt werden."
    local timestamp filename backup
    timestamp="$(date '+%Y%m%d-%H%M%S-%N')"
    filename="$(basename "$file")"
    backup="$BACKUP_DIR/${filename}.${timestamp}.bak"
    cp -a "$file" "$backup" || die "Backup von $file konnte nicht erstellt werden."
    [[ -e "$backup" ]] || die "Backup wurde nicht erstellt: $backup"
    ok "Backup erstellt: $backup"
}


files_equal() {
    local a="$1" b="$2"
    [[ -f "$a" && -f "$b" ]] && cmp -s -- "$a" "$b"
}

# Replace a regular file through a temporary sibling and rename(2). Keeping the
# temporary file in the destination directory guarantees that readers never
# observe a missing, truncated or partially copied live file, even when the
# source lives on another filesystem.
atomic_replace_file() {
    local src="$1" dst="$2" mode="${3:-644}" dst_dir tmp
    [[ -f "$src" ]] || return 1
    dst_dir="$(dirname "$dst")"
    mkdir -p "$dst_dir" || return 1
    tmp="$(mktemp "$dst_dir/.${dst##*/}.XXXXXX")" || return 1
    if ! cp -- "$src" "$tmp" || ! chmod "$mode" "$tmp" || ! mv -f -- "$tmp" "$dst"; then
        rm -f -- "$tmp"
        return 1
    fi
}

install_file_if_changed() {
    local src="$1" dst="$2" mode="${3:-644}" label="${4:-$(basename "$2")}"
    [[ -f "$src" ]] || die "Quelldatei fehlt: $src"

    if files_equal "$src" "$dst"; then
        chmod "$mode" "$dst" 2>/dev/null || true
        info "$label ist bereits aktuell"
        return 1
    fi

    backup_file "$dst"
    mkdir -p "$(dirname "$dst")" || die "Zielverzeichnis konnte nicht erstellt werden: $(dirname "$dst")"
    mv -- "$src" "$dst" || die "$label konnte nicht installiert werden: $dst"
    chmod "$mode" "$dst" || die "Berechtigungen konnten nicht gesetzt werden: $dst"
    ok "$label aktualisiert"
    return 0
}

copy_file_if_changed() {
    local src="$1" dst="$2" mode="${3:-644}" label="${4:-$(basename "$2")}" tmp
    [[ -f "$src" ]] || die "Quelldatei fehlt: $src"
    tmp="$(mktemp)" || die "Temporäre Datei für $label konnte nicht erstellt werden."
    cp -- "$src" "$tmp" || { rm -f "$tmp"; die "$label konnte nicht vorbereitet werden."; }
    if install_file_if_changed "$tmp" "$dst" "$mode" "$label"; then
        return 0
    fi
    rm -f "$tmp"
    return 1
}

render_template_if_changed() {
    local src="$1" dst="$2" mode="${3:-644}" label="${4:-$(basename "$2")}" tmp
    tmp="$(mktemp)" || die "Temporäre Datei für $label konnte nicht erstellt werden."
    render_template "$src" "$tmp"
    if install_file_if_changed "$tmp" "$dst" "$mode" "$label"; then
        return 0
    fi
    rm -f "$tmp"
    return 1
}
render_template() {
    local src="$1" dst="$2" data
    [[ -f "$src" ]] || die "Template fehlt: $src"
    data="$(<"$src")"
    data="${data//@APP_ID@/$APP_ID}"
    data="${data//@APP_NAME@/$APP_NAME}"
    data="${data//@APP_GENERIC_NAME@/$APP_GENERIC_NAME}"
    data="${data//@APP_COMMENT@/$APP_COMMENT}"
    data="${data//@APP_URL@/$APP_URL}"
    data="${data//@APP_CATEGORIES@/$APP_CATEGORIES}"
    data="${data//@APP_KEYWORDS@/$APP_KEYWORDS}"
    data="${data//@MOZ_APP_REMOTINGNAME@/$MOZ_APP_REMOTINGNAME}"
    data="${data//@WINDOW_CLASS@/$WINDOW_CLASS}"
    data="${data//@BROWSER_BRIDGE_PORT@/${BROWSER_BRIDGE_PORT:-}}"
    data="${data//@HYPR_SHARED_WORKSPACE@/${HYPR_SHARED_WORKSPACE:-}}"
    data="${data//@PROFILE_DIR@/$PROFILE_DIR}"
    data="${data//@LAUNCHER@/$LAUNCHER}"
    data="${data//@ICON_NAME@/$ICON_NAME}"
    printf '%s\n' "$data" > "$dst" || die "Template konnte nicht erzeugt werden: $dst"
}
