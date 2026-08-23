#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
FAKEBIN="$TMP/bin"
mkdir -p "$FAKEBIN" "$TMP/live" "$TMP/tx"

cat > "$FAKEBIN/cp" <<'SH'
#!/usr/bin/env bash
dst="${@: -1}"
if [[ "$(basename "$dst")" == .rules.lua.* ]]; then
    : > "$dst"
    sleep 0.2
fi
exec /usr/bin/cp "$@"
SH
chmod +x "$FAKEBIN/cp"
export PATH="$FAKEBIN:/usr/bin:/bin"

ROOT_DIR="$ROOT"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/hyprland.sh"
HYPR_RULES_FILE="$TMP/live/rules.lua"
HYPR_KEYBINDS_FILE="$TMP/live/keybinds.lua"
printf '%s\n' 'LIVE-ORIGINAL' > "$HYPR_RULES_FILE"
printf '%s\n' 'RESTORED-CONTENT' > "$TMP/tx/rules.original.lua"

_hypr_restore_originals "$TMP/tx/rules.original.lua" "$TMP/tx/missing.lua" true false &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
    [[ -s "$HYPR_RULES_FILE" ]]
    content="$(<"$HYPR_RULES_FILE")"
    [[ "$content" == "LIVE-ORIGINAL" || "$content" == "RESTORED-CONTENT" ]]
done
wait "$pid"
[[ "$(<"$HYPR_RULES_FILE")" == "RESTORED-CONTENT" ]]

echo "PASS: Hyprland rollback never exposes a missing, empty or partially copied live file"
