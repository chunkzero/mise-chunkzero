#!/usr/bin/env bash
# Installs chunk through the plugin from a local registry copy, then checks that a wrong checksum is rejected.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'kill "$server" 2>/dev/null; rm -rf "$work"' EXIT
cp -r "$root/test/registry" "$work/registry"
python3 -m http.server 8765 --bind 127.0.0.1 --directory "$work/registry" >/dev/null 2>&1 &
server=$!
sleep 1

export MISE_DATA_DIR="$work/data" MISE_CACHE_DIR="$work/cache" MISE_STATE_DIR="$work/state" MISE_CONFIG_DIR="$work/config"
export MISE_GLOBAL_CONFIG_FILE="$work/config/config.toml" MISE_YES=1 MISE_CHUNKZERO_REGISTRY=http://127.0.0.1:8765
mkdir -p "$work/project" && cd "$work/project"
mise plugins link chunkzero "$root"
cat > mise.toml <<'TOML'
[tools]
"chunkzero:chunk" = { version = "latest", channel = "nightly", prerelease = true, minimum_release_age = "0s" }
TOML
mise trust -q
mise install
mise exec -- chunk --version | grep -qx 'chunk 0.1.0-nightly.20261004.ge282f11816cd'

sed -i 's/"sha256": "[0-9a-f]*"/"sha256": "'"$(printf '0%.0s' {1..64})"'"/' "$work/registry/tools/chunk.json"
rm -rf "$MISE_DATA_DIR/installs" "$MISE_CACHE_DIR"
if mise install 2>"$work/error"; then
  echo "installed despite a wrong checksum" >&2
  exit 1
fi
grep -q "checksum mismatch" "$work/error"
echo "ok"
