#!/bin/bash
# Build the Mobius live/installer ISO. Run on Arch as root, after build-repo.sh.
#   sudo build/build-iso.sh [repo-dir] [out-dir]
# The live system is Arch's releng profile (stock kernel, known-good on any hardware)
# plus the Mobius installer and an offline copy of the Mobius package repo.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/build/config.sh"
repo="$(realpath "${1:-$root/out/repo}")"
out="$(realpath -m "${2:-$root/out/iso}")"
prof="$root/out/iso-profile"
[[ $EUID -eq 0 ]] || { echo "run as root (mkarchiso needs it)"; exit 1; }
[[ -f "$repo/mobius.db.tar.zst" ]] || { echo "no repo at $repo, run build-repo.sh first"; exit 1; }

rm -rf "$prof"
cp -a /usr/share/archiso/configs/releng "$prof"

# Identity
sed -i \
    -e 's/^iso_name=.*/iso_name="mobius"/' \
    -e 's/^iso_label=.*/iso_label="MOBIUS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
    -e 's/^iso_publisher=.*/iso_publisher="Mobius Linux"/' \
    -e 's/^iso_application=.*/iso_application="Mobius Linux installer"/' \
    "$prof/profiledef.sh"
sed -i 's|^  \["/usr/local/bin/livecd-sound"\]="0:0:755"|&\n  ["/usr/local/bin/mobius-install"]="0:0:755"|' "$prof/profiledef.sh"

# Extra live packages the installer needs
printf '%s\n' python gptfdisk btrfs-progs dosfstools arch-install-scripts >> "$prof/packages.x86_64"
sort -u -o "$prof/packages.x86_64" "$prof/packages.x86_64"

# Installer, with the release repo URL baked in
install -Dm755 "$root/installer/mobius-install" "$prof/airootfs/usr/local/bin/mobius-install"
sed -i "s|@MOBIUS_REPO_URL@|$MOBIUS_REPO_URL|" "$prof/airootfs/usr/local/bin/mobius-install"

# Offline Mobius repo (kernel, settings, metas, Claude, GE-Proton...)
mkdir -p "$prof/airootfs/opt/mobius-repo"
cp -a "$repo"/*.pkg.tar.zst "$repo"/mobius.db "$repo"/mobius.db.tar.zst "$repo"/mobius.files "$repo"/mobius.files.tar.zst "$prof/airootfs/opt/mobius-repo/"
rm -f "$prof"/airootfs/opt/mobius-repo/*-debug-*.pkg.tar.zst
# repo-add made symlinks; make them real files inside the image
for f in mobius.db mobius.files; do
    if [[ -L "$prof/airootfs/opt/mobius-repo/$f" ]]; then
        cp --remove-destination "$repo/$f.tar.zst" "$prof/airootfs/opt/mobius-repo/$f"
    fi
done

cat > "$prof/airootfs/etc/motd" <<'EOF'

  Mobius Linux live environment

  Install:      mobius-install
  Practice run: mobius-install --dry-run
  Wi-Fi:        iwctl     Network check: curl -I https://archlinux.org

EOF

mkdir -p "$out"
mkarchiso -v -w "$root/out/iso-work" -o "$out" "$prof"
rm -rf "$root/out/iso-work"
ls -lh "$out"
