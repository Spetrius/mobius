#!/bin/bash
# Test a freshly built repo before it is published. Runs as root in a clean archlinux:base-devel
# container (see .github/workflows/build.yml):  build/test-repo.sh out/repo
#   1. every Mobius meta package resolves against Arch + our repo (catches renamed/dropped deps)
#   2. the default Hyprland config in mobius-desktop passes Hyprland --verify-config
#   3. the Waybar config parses, and every shell script in our packages passes bash -n
set -euo pipefail
# Argument: a local repo directory, or a URL (to test the published repo)
src="${1:-out/repo}"
if [[ "$src" == *://* ]]; then server="$src"; else server="file://$(realpath "$src")"; fi
fail=0
step() { echo; echo "== $*"; }
bad()  { echo "FAIL: $*"; fail=1; }

grep -q '^\[multilib\]' /etc/pacman.conf || printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
# Signed repo: trust the Mobius key and require valid signatures, exactly like the installed systems
siglevel="Optional TrustAll"
if [[ -e "${server#file://}/mobius.db.sig" ]] || curl -fsL -r 0-0 -o /dev/null "$server/mobius.db.sig" 2>/dev/null; then
    key="$(dirname "$0")/../packages/mobius-keyring/mobius-signing-key.asc"
    pacman-key --init >/dev/null 2>&1; pacman-key --populate archlinux >/dev/null 2>&1
    pacman-key --add "$key" >/dev/null
    pacman-key --lsign-key "$(gpg --show-keys --with-colons "$key" | awk -F: '/^fpr/{print $10; exit}')" >/dev/null
    siglevel="Required"
fi
echo "repo signature level: $siglevel"
grep -q '^\[mobius\]' /etc/pacman.conf || printf '\n[mobius]\nSigLevel = %s\nServer = %s\n' "$siglevel" "$server" >> /etc/pacman.conf
pacman -Syu --noconfirm >/dev/null      # fresh container: bring it current first

step "dependency resolution"
# Everything a fresh install pulls, together (same set as the installer), then the hardware extras
for set in "mobius-base mobius-desktop mobius-gaming" "mobius-nvidia" "intel-ucode thermald vulkan-intel lib32-vulkan-intel intel-media-driver"; do
    if out="$(pacman -Sp --print-format '%n' $set 2>&1)"; then
        echo "ok: $set ($(wc -l <<<"$out") packages)"
    else
        bad "$set"; echo "$out" | grep -iE 'error|unable|conflict|not found|::' | head -20
    fi
done

step "package contents"
work="$(mktemp -d)"
mkdir -p "$work/cache"
mapfile -t ours < <(pacman -Slq mobius | grep -E '^mobius-' | sort -u)
pacman -Swdd --noconfirm --cachedir "$work/cache" "${ours[@]}" >/dev/null
for p in "${ours[@]}"; do
    v="$(pacman -Si "mobius/$p" | sed -n 's/^Version *: //p')"
    mkdir -p "$work/$p"; bsdtar -xf "$(ls "$work/cache/$p-$v-"*.pkg.tar.zst)" -C "$work/$p" 2>/dev/null
    while read -r f; do
        head -c 64 "$f" | grep -q '^#!/bin/bash\|^#!/usr/bin/env bash\|^#!/bin/sh' || continue
        bash -n "$f" 2>/dev/null || bad "bash -n $p:${f#"$work/$p"}"
    done < <(find "$work/$p/usr/bin" "$work/$p/usr/lib/mobius" -type f 2>/dev/null)
    while read -r f; do
        python3 -m py_compile "$f" 2>/dev/null || bad "python syntax $p:${f#"$work/$p"}"
    done < <(grep -rlE '^#!/usr/bin/(env )?python' "$work/$p/usr" 2>/dev/null || true)
done
echo "scripts checked"

skel="$work/mobius-desktop/etc/skel/.config"
python3 - "$skel/waybar/config.jsonc" <<'PY' || bad "waybar config"
import json, re, sys
json.loads(re.sub(r'^\s*//.*$', '', open(sys.argv[1], encoding='utf-8').read(), flags=re.M))
print("waybar config parses")
PY

step "Hyprland config"
pacman -S --noconfirm --needed hyprland >/dev/null
id tester >/dev/null 2>&1 || useradd -m tester
install -d -o tester /home/tester/.config /tmp/xdg-tester
cp -r "$skel/hypr" /home/tester/.config/; chown -R tester /home/tester/.config
res="$(su tester -s /bin/bash -c 'env HOME=/home/tester XDG_RUNTIME_DIR=/tmp/xdg-tester Hyprland --verify-config -c /home/tester/.config/hypr/hyprland.lua' 2>&1 | grep -v DEBUG | tail -5)"
echo "$res"
grep -q 'config ok' <<<"$res" || bad "Hyprland --verify-config"

echo
(( fail == 0 )) && echo "ALL TESTS PASSED" || { echo "TESTS FAILED"; exit 1; }
