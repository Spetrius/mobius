#!/bin/bash
# Move every AUR package in packages/aur.list to the current AUR HEAD commit.
# Review the diff (git diff packages/aur.list) and the upstream PKGBUILD changes before building.
set -euo pipefail
list="$(cd "$(dirname "$0")/.." && pwd)/packages/aur.list"
tmp="$(mktemp)"
while IFS= read -r line; do
    if [[ -z "$line" || "$line" == \#* ]]; then echo "$line"; continue; fi
    name="${line%% *}"
    commit="$(git ls-remote "https://aur.archlinux.org/$name.git" HEAD | cut -f1)"
    [[ -n "$commit" ]] || { echo "cannot resolve $name" >&2; exit 1; }
    echo "$name $commit"
done < "$list" > "$tmp"
mv "$tmp" "$list"
git -C "$(dirname "$list")" diff --stat -- aur.list || true
