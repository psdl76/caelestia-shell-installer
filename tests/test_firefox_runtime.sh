#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export USER="testuser"
FAKEBIN="$TMP/bin"
LOG_FIREFOX="$TMP/firefox.log"
LOG_HYPR="$TMP/hypr.log"
mkdir -p "$HOME/.config/hypr/hyprland" "$FAKEBIN"

cat > "$HOME/.config/hypr/hyprland/rules.lua" <<'LUA'
local opaque_tag = "opaque"
local communication_app_tag = "communication_app"
tagged_rule(opaque_tag, {
    "org.quickshell", -- Quickshell
}, "class")
tagged_rule(communication_app_tag, {
    "discord|equibop|vesktop", -- Discord clients
}, "class")
create_tag(communication_app_tag, { workspace = "special:communication" })
LUA

cat > "$HOME/.config/hypr/hyprland/keybinds.lua" <<'LUA'
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
LUA

cat > "$FAKEBIN/firefox" <<'EOF_FIREFOX'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo 'Mozilla Firefox 153.0.4'; exit 0 ;;
  --help) echo '--profile --new-instance --new-window'; exit 0 ;;
esac
printf '%s|%s\n' "${MOZ_APP_REMOTINGNAME:-}" "$*" >> "${TEST_FIREFOX_LOG:?}"
exit "${TEST_FIREFOX_EXIT:-0}"
EOF_FIREFOX

cat > "$FAKEBIN/curl" <<'EOF_CURL'
#!/usr/bin/env bash
set -e
out=""
while (($#)); do
  if [[ "$1" == "--output" ]]; then shift; out="$1"; fi
  shift || true
done
[[ -n "$out" ]]
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><path d="M0 0h1v1H0z"/></svg>' > "$out"
EOF_CURL

cat > "$FAKEBIN/hyprctl" <<'EOF_HYPR'
#!/usr/bin/env bash
case "${1:-}" in
  clients)
    [[ "${2:-}" == "-j" ]] && printf '%s\n' "${TEST_HYPR_CLIENTS:-[]}" || exit 1
    ;;
  monitors)
    [[ "${2:-}" == "-j" ]] && printf '%s\n' "${TEST_HYPR_MONITORS:-[]}" || exit 1
    ;;
  dispatch)
    printf '%s\n' "$*" >> "${TEST_HYPR_LOG:?}"
    ;;
  reload) echo ok ;;
  configerrors) echo 'no errors' ;;
  *) exit 0 ;;
esac
EOF_HYPR

for cmd in desktop-file-validate update-desktop-database gtk-update-icon-cache; do
cat > "$FAKEBIN/$cmd" <<'EOF_STUB'
#!/usr/bin/env bash
exit 0
EOF_STUB
chmod +x "$FAKEBIN/$cmd"
done
chmod +x "$FAKEBIN/firefox" "$FAKEBIN/curl" "$FAKEBIN/hyprctl"
export PATH="$FAKEBIN:/usr/bin:/bin"
export TEST_FIREFOX_LOG="$LOG_FIREFOX"
export TEST_HYPR_LOG="$LOG_HYPR"
: > "$LOG_FIREFOX"
: > "$LOG_HYPR"

# Install one normal app and one special-workspace app into the isolated HOME.
"$ROOT_DIR/install.sh" chatgpt --no-applet >/dev/null
"$ROOT_DIR/install.sh" google-messages --no-applet >/dev/null

CHAT="$HOME/.local/bin/caelestia-webapp-chatgpt"
CHAT_SETUP="$HOME/.local/bin/caelestia-webapp-chatgpt-setup"
MSG="$HOME/.local/bin/caelestia-webapp-google-messages"

# Generated runtime properties and required Firefox arguments.
grep -Fq 'WINDOW_CLASS="chatgpt"' "$CHAT"
grep -Fq 'SPECIAL_WORKSPACE=""' "$CHAT"
grep -Fq 'SPECIAL_WORKSPACE="communication"' "$MSG"

export TEST_HYPR_CLIENTS='[]'
export TEST_HYPR_MONITORS='[]'
"$CHAT"
grep -Fq 'chatgpt|--new-instance --profile ' "$LOG_FIREFOX"
grep -Fq -- '--new-window https://chatgpt.com/' "$LOG_FIREFOX"

# A running app is focused by its exact Hyprland address; Firefox is not called again.
before="$(wc -l < "$LOG_FIREFOX")"
export TEST_HYPR_CLIENTS='[{"address":"0xabc","class":"chatgpt","initialClass":"chatgpt"}]'
"$CHAT"
after="$(wc -l < "$LOG_FIREFOX")"
[[ "$before" == "$after" ]] || { echo 'FAIL: running ChatGPT started another Firefox instance' >&2; exit 1; }
grep -Fq 'dispatch hl.dsp.focus({ window = "address:0xabc" })' "$LOG_HYPR"

# Special-workspace launch opens communication when it is not visible.
: > "$LOG_HYPR"
export TEST_HYPR_CLIENTS='[]'
export TEST_HYPR_MONITORS='[{"specialWorkspace":{"name":""}}]'
"$MSG"
grep -Fq 'dispatch togglespecialworkspace communication' "$LOG_HYPR"
grep -Fq 'google-messages|--new-instance --profile ' "$LOG_FIREFOX"

# Existing messaging app: open workspace and focus existing address, no Firefox duplicate.
: > "$LOG_HYPR"
before="$(wc -l < "$LOG_FIREFOX")"
export TEST_HYPR_CLIENTS='[{"address":"0xdef","class":"google-messages","initialClass":"google-messages"}]'
export TEST_HYPR_MONITORS='[{"specialWorkspace":{"name":""}}]'
"$MSG"
after="$(wc -l < "$LOG_FIREFOX")"
[[ "$before" == "$after" ]] || { echo 'FAIL: running Google Messages started another Firefox instance' >&2; exit 1; }
grep -Fq 'dispatch togglespecialworkspace communication' "$LOG_HYPR"
grep -Fq 'dispatch hl.dsp.focus({ window = "address:0xdef" })' "$LOG_HYPR"

# If the special workspace is already visible, activate without toggling it closed.
: > "$LOG_HYPR"
export TEST_HYPR_MONITORS='[{"specialWorkspace":{"name":"special:communication"}}]'
"$MSG"
! grep -Fq 'togglespecialworkspace communication' "$LOG_HYPR"
grep -Fq 'dispatch hl.dsp.focus({ window = "address:0xdef" })' "$LOG_HYPR"

# Setup mode refuses to rewrite CSS while the app is running and focuses it instead.
app_css="$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/chrome/userChrome.app.css"
active_css="$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/chrome/userChrome.css"
before_hash="$(sha256sum "$active_css" | awk '{print $1}')"
before="$(wc -l < "$LOG_FIREFOX")"
export TEST_HYPR_CLIENTS='[{"address":"0xabc","class":"chatgpt","initialClass":"chatgpt"}]'
set +e
"$CHAT_SETUP" >/dev/null 2>&1
status=$?
set -e
[[ "$status" -eq 2 ]] || { echo "FAIL: setup-running exit code was $status, expected 2" >&2; exit 1; }
after="$(wc -l < "$LOG_FIREFOX")"
[[ "$before" == "$after" ]] || { echo 'FAIL: setup mode started Firefox while app was already running' >&2; exit 1; }
[[ "$before_hash" == "$(sha256sum "$active_css" | awk '{print $1}')" ]] || { echo 'FAIL: setup mode changed CSS while app was running' >&2; exit 1; }

# Setup mode when stopped shows setup CSS only for that process lifetime and restores app mode.
export TEST_HYPR_CLIENTS='[]'
"$CHAT_SETUP" >/dev/null
cmp -s "$active_css" "$app_css" || { echo 'FAIL: setup launcher did not restore app CSS on exit' >&2; exit 1; }
tail -n 1 "$LOG_FIREFOX" | grep -Fq 'chatgpt|--new-instance --profile '

# Profile customization remains isolated to the dedicated profile.
grep -Fq 'toolkit.legacyUserProfileCustomizations.stylesheets' "$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/user.js"
grep -Fq 'user_pref("browser.sessionstore.resume_from_crash", false);' "$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/user.js" || {
    echo 'FAIL: dedicated WebApp profile does not disable Firefox crash session restore' >&2
    exit 1
}
grep -Fq 'user_pref("browser.sessionstore.resume_session_once", false);' "$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/user.js" || {
    echo 'FAIL: dedicated WebApp profile does not disable one-shot OS session restore' >&2
    exit 1
}
# Regression: repair/upgrade must apply the no-session-restore policy to an existing profile.
profile_user_js="$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/user.js"
sed -i 's/browser.sessionstore.resume_from_crash", false/browser.sessionstore.resume_from_crash", true/' "$profile_user_js"
sed -i '/browser.sessionstore.resume_session_once/d' "$profile_user_js"
grep -Fq 'user_pref("browser.sessionstore.resume_from_crash", true);' "$profile_user_js"
! grep -Fq 'browser.sessionstore.resume_session_once' "$profile_user_js"
"$ROOT_DIR/repair.sh" --app chatgpt --quiet
grep -Fq 'user_pref("browser.sessionstore.resume_from_crash", false);' "$profile_user_js" || {
    echo 'FAIL: repair did not migrate existing WebApp profile away from crash session restore' >&2
    exit 1
}
grep -Fq 'user_pref("browser.sessionstore.resume_session_once", false);' "$profile_user_js" || {
    echo 'FAIL: repair did not restore the one-shot OS session restore guard' >&2
    exit 1
}
! grep -Fq 'user_pref("browser.sessionstore.resume_from_crash", true);' "$profile_user_js" || {
    echo 'FAIL: repair left crash session restore enabled in existing WebApp profile' >&2
    exit 1
}
grep -Fq '#TabsToolbar' "$app_css"
! grep -Fq '#TabsToolbar' "$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile/chrome/userChrome.setup.css"

echo 'PASS: Firefox runtime uses dedicated profiles, setup mode and activate-or-launch without duplicate instances'


# Regression: old focuswindow syntax is forbidden in generated launchers.
! grep -Fq 'hyprctl dispatch focuswindow "address:' "$CHAT" || {
    echo 'FAIL: legacy Hyprland focuswindow syntax remains in ChatGPT launcher' >&2
    exit 1
}
grep -Fq 'hl.dsp.focus({ window = \"address:$address\" })' "$CHAT"
grep -Fq 'existing_address="$(find_existing_window || true)"' "$CHAT"

# A focus dispatcher failure must still not start a duplicate Firefox instance.
cat > "$FAKEBIN/hyprctl" <<'EOF_HYPR_FAIL_FOCUS'
#!/usr/bin/env bash
case "${1:-}" in
  clients)
    [[ "${2:-}" == "-j" ]] && printf '%s\n' "${TEST_HYPR_CLIENTS:-[]}" || exit 1
    ;;
  monitors)
    [[ "${2:-}" == "-j" ]] && printf '%s\n' "${TEST_HYPR_MONITORS:-[]}" || exit 1
    ;;
  dispatch)
    printf '%s\n' "$*" >> "${TEST_HYPR_LOG:?}"
    [[ "$*" == *'hl.dsp.focus('* ]] && exit 7
    exit 0
    ;;
  *) exit 0 ;;
esac
EOF_HYPR_FAIL_FOCUS
chmod +x "$FAKEBIN/hyprctl"

before="$(wc -l < "$LOG_FIREFOX")"
export TEST_HYPR_CLIENTS='[{"address":"0xbeef","class":"chatgpt","initialClass":"chatgpt"}]'
"$CHAT" >/dev/null 2>&1
after="$(wc -l < "$LOG_FIREFOX")"
[[ "$before" == "$after" ]] || {
    echo 'FAIL: focus failure started a duplicate Firefox instance' >&2
    exit 1
}

echo 'PASS: focus failure cannot cause a duplicate WebApp instance'
