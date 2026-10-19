#!/bin/bash
# Build every Mobius package into a pacman repo. Run on Arch as a normal user with sudo.
#   build/build-repo.sh [outdir]        default outdir: ./out/repo
#   SKIP_PKGS="linux-mobius" build/build-repo.sh    skip named packages
#   KEEP_GOING=1 build/build-repo.sh                 report failures instead of stopping
# Skips anything whose exact version is already in outdir, so reruns are cheap.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/build/config.sh"
out="$(realpath -m "${1:-$root/out/repo}")"
work="$root/out/work"
mkdir -p "$out" "$work"

# Let later packages depend on earlier ones: expose $out as a local [mobius] repo.
setup_local_repo() {
    [[ -f "$out/mobius.db.tar.zst" ]] || repo-add -q "$out/mobius.db.tar.zst"
    if ! grep -q '^\[mobius\]' /etc/pacman.conf; then
        printf '\n[mobius]\nSigLevel = Optional TrustAll\nServer = file://%s\n' "$out" | sudo tee -a /etc/pacman.conf >/dev/null
    fi
    sudo pacman -Sy --noconfirm >/dev/null
}

already_built() {   # $1 = dir with PKGBUILD
    local f
    while read -r f; do [[ "$f" == *-debug-* || -f "$out/$(basename "$f")" ]] || return 1; done \
        < <(cd "$1" && PKGDEST="$out" makepkg --packagelist)
}

install_build_deps() {  # $1 = dir with PKGBUILD
    # Install makedepends/checkdepends, plus any depends the repos can already satisfy.
    # Runtime deps that only exist later in this build (e.g. ntsync-autoload, provided by
    # mobius-settings) are skipped; makepkg -d then doesn't insist on them.
    local dep want=()
    while read -r dep; do
        pacman -T "$dep" >/dev/null 2>&1 && continue                    # already installed
        pacman -Sp --print-format '%n' "$dep" >/dev/null 2>&1 && want+=("$dep")
    done < <(cd "$1" && makepkg --printsrcinfo \
        | sed -n 's/^\t\(make\|check\)\?depends = //p' | sort -u)
    if (( ${#want[@]} )); then
        sudo pacman -S --needed --noconfirm --asdeps "${want[@]}"
    fi
}

build_dir() {       # $1 = dir with PKGBUILD
    local d="$1" name; name="$(basename "$d")"
    if [[ " ${SKIP_PKGS:-} " == *" $name "* ]]; then echo "== $name: skipped (SKIP_PKGS)"; return; fi
    if already_built "$d"; then echo "== $name: up to date"; return; fi
    echo "== $name: building"
    install_build_deps "$d"
    # Signing keys for verified sources (Arch convention: keys/pgp/<fingerprint>.asc)
    if compgen -G "$d/keys/pgp/*.asc" >/dev/null; then
        gpg --batch --quiet --import "$d"/keys/pgp/*.asc
    fi
    # -d: deps are handled above, so runtime deps on not-yet-built packages don't block the build
    if ! (cd "$d" && env -u CI -u GITHUB_RUN_ID PKGDEST="$out" makepkg -d --noconfirm --needed -f); then
        [[ -n "${KEEP_GOING:-}" ]] || exit 1
        echo "== $name: FAILED (continuing, KEEP_GOING set)"; failed+=("$name"); return
    fi
    (cd "$d" && PKGDEST="$out" makepkg --packagelist) | while read -r f; do
        [[ -f "$f" ]] || continue   # e.g. -debug split packages that weren't produced
        repo-add -q -R "$out/mobius.db.tar.zst" "$f"
    done
    sudo pacman -Sy --noconfirm >/dev/null
}

failed=()
setup_local_repo

# Our own packages, with @MOBIUS_GH@ filled in
for p in "${MOBIUS_LOCAL_PKGS[@]}"; do
    rm -rf "$work/$p"; cp -a "$root/packages/$p" "$work/$p"
    { grep -rl "@MOBIUS_GH@" "$work/$p" || true; } | xargs -r sed -i "s|@MOBIUS_GH@|$MOBIUS_GH|g"
done

# AUR packages first (mobius-settings and mobius-base depend on some of them)
while read -r name commit; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    d="$work/aur/$name"
    if [[ ! -d "$d/.git" ]]; then git clone -q "https://aur.archlinux.org/$name.git" "$d"; fi
    git -C "$d" fetch -q origin && git -C "$d" checkout -q --force "$commit"
    # GitHub release assets can't hold ':' so epoch'd filenames (1:foo) would 404. Drop the epoch.
    sed -i '/^epoch=/d' "$d/PKGBUILD"
    build_dir "$d"
done < "$root/packages/aur.list"

for p in "${MOBIUS_LOCAL_PKGS[@]}"; do build_dir "$work/$p"; done

if (( ${#failed[@]} )); then echo "FAILED: ${failed[*]}"; fi
echo "Repo ready: $out"
ls -1 "$out" | grep -c '\.pkg\.tar\.zst$' | xargs echo "packages:"
