#!/usr/bin/env bash

check_firefox() {
    require_command firefox "sudo pacman -S firefox"
    local version help
    version="$(firefox --version 2>&1 || true)"
    [[ -n "$version" ]] || die "Firefox liefert keine Versionsinformation."
    info "$version"
    help="$(firefox --help 2>&1 || true)"
    [[ -n "$help" ]] || die "firefox --help liefert keine Ausgabe."
    for option in --profile --new-instance --new-window; do
        grep -q -- "$option" <<< "$help" || die "Firefox unterstützt $option laut --help nicht."
        ok "Firefox unterstützt $option"
    done
}

install_firefox_profile() {
    mkdir -p "$PROFILE_DIR" "$CHROME_DIR" || die "Firefox-Profilverzeichnisse konnten nicht erstellt werden."
    verify_directory "$PROFILE_DIR"
    verify_directory "$CHROME_DIR"

    if render_template_if_changed "$TEMPLATE_DIR/user.js.tpl" "$USER_JS" 644 "Firefox user.js"; then
        :
    fi
    verify_file "$USER_JS"
    verify_contains "$USER_JS" 'toolkit.legacyUserProfileCustomizations.stylesheets'
    verify_contains "$USER_JS" "$APP_URL"
    verify_contains "$USER_JS" 'browser.sessionstore.resume_from_crash", false'
    verify_contains "$USER_JS" 'browser.sessionstore.resume_session_once", false'

    if copy_file_if_changed "$TEMPLATE_DIR/userChrome.app.css" "$APP_USER_CHROME" 644 "Firefox App-Mode CSS"; then :; fi
    if copy_file_if_changed "$TEMPLATE_DIR/userChrome.setup.css" "$SETUP_USER_CHROME" 644 "Firefox Setup-Mode CSS"; then :; fi
    # Installer always leaves the profile in normal app mode. If setup mode was
    # active, only this file changes and is backed up once.
    if copy_file_if_changed "$TEMPLATE_DIR/userChrome.app.css" "$USER_CHROME" 644 "Aktive userChrome.css"; then :; fi

    verify_file "$APP_USER_CHROME"
    verify_contains "$APP_USER_CHROME" '#TabsToolbar'
    verify_contains "$APP_USER_CHROME" '#nav-bar'
    verify_file "$SETUP_USER_CHROME"
    verify_contains "$SETUP_USER_CHROME" '#navigator-toolbox'
    verify_file "$USER_CHROME"
    cmp -s "$USER_CHROME" "$APP_USER_CHROME" || die "Aktive userChrome.css entspricht nach Installation nicht dem App-Modus."
    ok "Firefox App- und Setup-Modus installiert"
}

install_launcher() {
    if render_template_if_changed "$TEMPLATE_DIR/launcher.sh.tpl" "$LAUNCHER" 755 "Launcher"; then :; fi
    verify_file "$LAUNCHER"
    [[ -x "$LAUNCHER" ]] || die "Launcher ist nicht ausführbar."
    verify_contains "$LAUNCHER" "MOZ_APP_REMOTINGNAME=$MOZ_APP_REMOTINGNAME"
    verify_contains "$LAUNCHER" "$APP_URL"
    verify_contains "$LAUNCHER" "WINDOW_CLASS=\"$WINDOW_CLASS\""
    verify_contains "$LAUNCHER" 'find_existing_window'
    verify_contains "$LAUNCHER" 'focus_existing_window'
    bash -n "$LAUNCHER" || die "Der erzeugte Launcher enthält einen Bash-Syntaxfehler."
    ok "Launcher ist syntaktisch gültig"
}

install_setup_launcher() {
    if render_template_if_changed "$TEMPLATE_DIR/setup-launcher.sh.tpl" "$SETUP_LAUNCHER" 755 "Setup-Launcher"; then :; fi
    verify_file "$SETUP_LAUNCHER"
    [[ -x "$SETUP_LAUNCHER" ]] || die "Setup-Launcher ist nicht ausführbar."
    verify_contains "$SETUP_LAUNCHER" "MOZ_APP_REMOTINGNAME=$MOZ_APP_REMOTINGNAME"
    verify_contains "$SETUP_LAUNCHER" "$APP_URL"
    verify_contains "$SETUP_LAUNCHER" "WINDOW_CLASS=\"$WINDOW_CLASS\""
    verify_contains "$SETUP_LAUNCHER" 'userChrome.setup.css'
    verify_contains "$SETUP_LAUNCHER" 'find_existing_window'
    bash -n "$SETUP_LAUNCHER" || die "Der erzeugte Setup-Launcher enthält einen Bash-Syntaxfehler."
    ok "Setup-Launcher ist syntaktisch gültig"
}
