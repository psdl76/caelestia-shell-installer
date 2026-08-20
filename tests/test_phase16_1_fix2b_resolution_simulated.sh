#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home"
cat > "$TMP/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -e
url=""; out=""
while (($#)); do
  case "$1" in
    -o) out="$2"; shift 2;;
    http*) url="$1"; shift;;
    *) shift;;
  esac
done
[[ -n "$out" && -n "$url" ]]
case "$url" in
  *dashboard-icons*'/airbnb.'*|*dashboard-icons*'/ard.'*|*dashboard-icons*'/booking.'*|*dashboard-icons*'/canva.'*|*dashboard-icons*'/deutsche-bahn.'*|*dashboard-icons*'/etsy.'*|*dashboard-icons*'/joyn.'*|*dashboard-icons*'/magenta-tv.'*|*dashboard-icons*'/pcloud.'*|*dashboard-icons*'/stackoverflow.'*|*dashboard-icons*'/wow.'*|*dashboard-icons*'/zdf.'*) exit 22;;
esac
if [[ "$url" == *google.com/s2/favicons* ]]; then
  printf '\x89PNG\r\n\x1a\nFAKE' > "$out"
elif [[ "$url" == *.svg || "$url" == *lobehub* ]]; then
  printf '<svg xmlns="http://www.w3.org/2000/svg"><rect width="1" height="1"/></svg>\n' > "$out"
elif [[ "$url" == *.png ]]; then
  printf '\x89PNG\r\n\x1a\nFAKE' > "$out"
else
  printf 'RIFFxxxxWEBPFAKE' > "$out"
fi
CURL
chmod +x "$TMP/bin/curl"
PATH="$TMP/bin:$PATH" HOME="$TMP/home" XDG_CACHE_HOME="$TMP/cache" XDG_STATE_HOME="$TMP/state" \
  "$ROOT_DIR/scripts/prepare_store_icons.sh" >/dev/null
python3 "$ROOT_DIR/scripts/validate_store_icons.py" \
  --root "$ROOT_DIR" --cache "$TMP/cache/caelestia-webapps/store-icons-v6" >/dev/null

grep -q 'SUMMARY total=79 resolved=79 unresolved=0' "$TMP/state/caelestia-webapps/icon-pipeline.log"
echo "PASS: simulated 79/79 icon resolution including website fallback"
