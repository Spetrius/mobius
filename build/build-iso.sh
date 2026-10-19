#!/bin/bash
# Build the Mobius live/installer ISO. Run on Arch as root.
#   sudo build/build-iso.sh [out-dir]
# The live system is Arch's releng profile (stock kernel, known-good on any hardware)
# plus the Mobius installer. Mobius packages are downloaded from the published repo
# during install (GitHub release assets max out at 2 GB, an offline copy made it 2.6 GB).
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/build/config.sh"
out="$(realpath -m "${1:-$root/out/iso}")"
prof="$root/out/iso-profile"
[[ $EUID -eq 0 ]] || { echo "run as root (mkarchiso needs it)"; exit 1; }

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
