#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/testlib.sh"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/bin/caelestia-webapps"
HOME="$TEST_ROOT/home"
export HOME
mkdir -p "$HOME/.local/share/caelestia-webapps/apps/chatgpt" "$HOME/.local/bin"
printf 'APP_ID="chatgpt"\n' > "$HOME/.local/share/caelestia-webapps/apps/chatgpt/installed.conf"
cat > "$HOME/.local/bin/caelestia-webapp-chatgpt" <<'EOF'
#!/usr/bin/env bash
printf 'launched\n' > "$HOME/launch-marker"
EOF
chmod +x "$HOME/.local/bin/caelestia-webapp-chatgpt"
cat > "$HOME/.local/bin/caelestia-webapp-chatgpt-setup" <<'EOF'
#!/usr/bin/env bash
printf 'setup\n' > "$HOME/setup-marker"
EOF
chmod +x "$HOME/.local/bin/caelestia-webapp-chatgpt-setup"

out="$($CLI launch chatgpt)"
python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["ok"] and d["data"]["accepted"]' <<<"$out"
for _ in {1..40}; do [[ -f "$HOME/launch-marker" ]] && break; sleep 0.025; done
assert_file "$HOME/launch-marker"

out="$($CLI setup chatgpt)"
python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["ok"] and d["data"]["accepted"]' <<<"$out"
for _ in {1..40}; do [[ -f "$HOME/setup-marker" ]] && break; sleep 0.025; done
assert_file "$HOME/setup-marker"
pass "launch/setup API asynchronously executes generated launchers"
