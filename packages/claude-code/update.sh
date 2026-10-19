#!/bin/bash
# Bump claude-code to the current stable release and pin its manifest checksum.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
base=https://downloads.claude.ai/claude-code-releases
ver="$(curl -fsSL "$base/stable")"
[[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "bad version: $ver" >&2; exit 1; }
sha="$(curl -fsSL "$base/$ver/manifest.json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["platforms"]["linux-x64"]["checksum"])')"
[[ "$sha" =~ ^[a-f0-9]{64}$ ]] || { echo "bad checksum" >&2; exit 1; }
sed -i -e "s/^pkgver=.*/pkgver=$ver/" -e "s/^pkgrel=.*/pkgrel=1/" \
       -e "s/^sha256sums=.*/sha256sums=('$sha')/" "$here/PKGBUILD"
echo "claude-code -> $ver ($sha)"
