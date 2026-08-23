#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(<"$ROOT/VERSION")"
OUT="${1:-$ROOT/dist/release-$VERSION}"
TOP="caelestia-webapps-$VERSION"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

[[ "$VERSION" == "0.4.3" ]]
bash "$ROOT/tests/run_phase18_2_gate.sh"
bash "$ROOT/tests/test_runtime_tarball_reproducible_01.sh"
python3 "$ROOT/tests/test_branding_assets.py"
python3 "$ROOT/tests/test_phase20_1_product_branding.py"
python3 "$ROOT/tests/test_release_0_4_3.py"
bash "$ROOT/tests/run_phase19_aur_gate.sh"

mkdir -p "$OUT"
TARBALL="$("$ROOT/packaging/make-runtime-tarball.sh" "$VERSION" "$OUT")"
LIST="$TMP/members"
tar -tzf "$TARBALL" > "$LIST"
awk -v top="$TOP" '$0 != top "/" && index($0, top "/") != 1 { exit 1 }' "$LIST"
! grep -Eq '(^|/)(\.git|tests|__pycache__|\.pytest_cache|\.zed|\.vscode)(/|$)' "$LIST"
grep -Fqx "$TOP/VERSION" "$LIST"
grep -Fqx "$TOP/assets/branding/caelestia-webapps.svg" "$LIST"
grep -Fqx "$TOP/manager/style/AnimatedBrandLogo.qml" "$LIST"
grep -Fqx "$TOP/packaging/install-core.sh" "$LIST"
grep -Fqx "$TOP/packaging/uninstall-core.sh" "$LIST"
grep -Fqx "$TOP/packaging/runtime-entries.txt" "$LIST"

tar -xzf "$TARBALL" -C "$TMP"
EXTRACTED="$TMP/$TOP"
PREFIX="$TMP/prefix"
"$EXTRACTED/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
grep -Fqx "PACKAGE_VERSION=$VERSION" "$PREFIX/lib/caelestia-webapps/PACKAGE-METADATA"

# Exercise the installed public entry points from the extracted artifact. No
# source-checkout script may stand in for the shipped CLI or Manager wrapper.
TEST_HOME="$TMP/home"
mkdir -p "$TEST_HOME/config" "$TEST_HOME/data" "$TEST_HOME/state" \
    "$TEST_HOME/cache" "$TEST_HOME/runtime" "$TMP/fake-bin"
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/config" \
XDG_DATA_HOME="$TEST_HOME/data" \
XDG_STATE_HOME="$TEST_HOME/state" \
XDG_CACHE_HOME="$TEST_HOME/cache" \
XDG_RUNTIME_DIR="$TEST_HOME/runtime" \
    "$PREFIX/bin/caelestia-webapps" list > "$TMP/list.json"
python3 - "$TMP/list.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload.get("apiVersion") == 1
assert payload.get("ok") is True
assert payload.get("command") == "list"
PY
cat > "$TMP/fake-bin/qs" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${CAELESTIA_WEBAPPS_ROOT:-}" > "${QS_ROOT_LOG:?}"
printf '%s\n' "$*" > "${QS_ARGS_LOG:?}"
EOF
chmod +x "$TMP/fake-bin/qs"
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/config" \
XDG_DATA_HOME="$TEST_HOME/data" \
XDG_STATE_HOME="$TEST_HOME/state" \
XDG_CACHE_HOME="$TEST_HOME/cache" \
XDG_RUNTIME_DIR="$TEST_HOME/runtime" \
PATH="$TMP/fake-bin:/usr/bin:/bin" \
QS_ROOT_LOG="$TMP/qs-root.log" \
QS_ARGS_LOG="$TMP/qs-args.log" \
    "$PREFIX/bin/caelestia-webapps-manager"
grep -Fqx "$PREFIX/lib/caelestia-webapps" "$TMP/qs-root.log"
grep -Fq "$PREFIX/lib/caelestia-webapps/manager/shell.qml" "$TMP/qs-args.log"

"$EXTRACTED/packaging/uninstall-core.sh" --prefix "$PREFIX" >/dev/null
[[ ! -e "$PREFIX/lib/caelestia-webapps" ]]

"$ROOT/packaging/build-arch-package.sh" "$OUT/arch"
PACKAGE="$(find "$OUT/arch" -maxdepth 1 -type f -name "caelestia-webapps-$VERSION-1-any.pkg.tar.*" -print -quit)"
[[ -n "$PACKAGE" && -f "$PACKAGE" ]]
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/bin/caelestia-webapps-manager'
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/lib/caelestia-webapps/assets/branding/caelestia-webapps.svg'
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/share/icons/hicolor/scalable/apps/caelestia-webapps.svg'

(
    cd "$OUT"
    sha256sum "$(basename -- "$TARBALL")" "arch/$(basename -- "$PACKAGE")" > SHA256SUMS
    sha256sum -c SHA256SUMS
)

echo "PASS: Caelestia WebApps $VERSION local release artifacts"
