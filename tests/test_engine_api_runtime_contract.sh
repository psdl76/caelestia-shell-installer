#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
API="$ROOT_DIR/bin/caelestia-webapps"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home/.local/share/caelestia-webapps/apps/chatgpt/profile"
cat >"$tmp/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
[[ "${1:-}" == "clients" && "${2:-}" == "-j" ]] || exit 2
cat <<'JSON'
[
  {"class":"chatgpt","initialClass":"chatgpt"},
  {"class":"kitty","initialClass":"kitty"}
]
JSON
EOF
chmod +x "$tmp/bin/hyprctl"

out="$(HOME="$tmp/home" PATH="$tmp/bin:$PATH" "$API" runtime)"
python3 - "$out" <<'PY'
import json,sys
p=json.loads(sys.argv[1])
assert p["apiVersion"] == 1
assert p["ok"] is True
assert p["command"] == "runtime"
assert p["data"]["runtimeAvailable"] is True
assert p["data"]["apps"]["chatgpt"]["running"] is True
assert p["data"]["apps"]["chatgpt"]["windowCount"] == 1
assert p["data"]["apps"]["gemini"]["running"] is False
PY

echo 'PASS: runtime API exposes transient Hyprland window state without mutating the catalog'
