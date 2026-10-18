#!/bin/bash
# Bump claude-desktop to the newest version in Anthropic's apt repo.
# Trust chain: pinned key fingerprint -> signed InRelease -> Packages sha256 -> .deb sha256.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
base=https://downloads.claude.ai/claude-desktop
fpr=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$base/key.asc" -o "$tmp/key.asc"
gpg --show-keys --with-colons "$tmp/key.asc" | grep -q "^fpr:::::::::$fpr:" \
  || { echo "signing key fingerprint mismatch" >&2; exit 1; }
gpg --dearmor < "$tmp/key.asc" > "$tmp/key.gpg"

curl -fsSL "$base/apt/stable/dists/stable/InRelease" -o "$tmp/InRelease"
gpgv --keyring "$tmp/key.gpg" --output "$tmp/Release" "$tmp/InRelease"

curl -fsSL "$base/apt/stable/dists/stable/main/binary-amd64/Packages" -o "$tmp/Packages"
want="$(awk '/^SHA256:/{f=1;next} /^[A-Z]/{f=0} f && $3=="main/binary-amd64/Packages"{print $1}' "$tmp/Release")"
have="$(sha256sum "$tmp/Packages" | cut -d' ' -f1)"
[[ -n "$want" && "$want" == "$have" ]] || { echo "Packages index hash mismatch" >&2; exit 1; }

read -r ver sha < <(awk '
  /^Package:/{p=$2} /^Version:/{v=$2} /^SHA256:/{s=$2}
  /^$/{ if (p=="claude-desktop") print v, s; p=v=s="" }
  END{ if (p=="claude-desktop") print v, s }' "$tmp/Packages" | sort -V | tail -1)

sed -i -e "s/^pkgver=.*/pkgver=$ver/" -e "s/^pkgrel=.*/pkgrel=1/" \
       -e "s/^sha256sums=.*/sha256sums=('$sha')/" "$here/PKGBUILD"
echo "claude-desktop -> $ver ($sha)"
