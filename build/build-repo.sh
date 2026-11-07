#!/bin/bash
# Build every Mobius package into a pacman repo. Run on Arch as a normal user with sudo.
#   build/build-repo.sh [outdir]        default outdir: ./out/repo
#   SKIP_PKGS="linux-mobius" build/build-repo.sh    skip named packages
#   KEEP_GOING=1 build/build-repo.sh                 report failures instead of stopping
#   MOBIUS_SIGNING_KEY="$(cat key.asc)" build/...   sign packages and the database (CI secret)
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
    # Always install makedepends/checkdepends. Runtime depends only matter when the
    # package compiles something (prepare/build/check); metas and repacks skip them, so
    # they never drag unrelated packages (or conflicts) into the build environment.
    # Deps the repos can't satisfy yet (built later in this run) are skipped; makepkg -d
    # then doesn't insist on them.
    local dep want=() kinds='\(make\|check\)depends'
    if grep -qE '^[[:space:]]*(prepare|build|check)[[:space:]]*\(\)' "$1/PKGBUILD"; then
        kinds='\(make\|check\)\?depends'
    fi
    while read -r dep; do
        pacman -T "$dep" >/dev/null 2>&1 && continue                    # already installed
        pacman -Sp --print-format '%n' "$dep" >/dev/null 2>&1 && want+=("$dep")
    done < <(cd "$1" && makepkg --printsrcinfo \
        | sed -n "s/^\t${kinds} = //p" | sort -u)
    if (( ${#want[@]} )); then
        sudo pacman -S --needed --noconfirm --asdeps "${want[@]}"
    fi
}

register_built() {  # $1 = dir with PKGBUILD: built earlier (e.g. cached by a failed run) but not in the database
    local f entry added=0
    while read -r f; do
        [[ -f "$f" ]] || continue
        entry="$(basename "$f")"; entry="${entry%-*.pkg.tar.zst}"      # name-ver-rel
        if ! bsdtar -tf "$out/mobius.db.tar.zst" 2>/dev/null | grep -qx "$entry/"; then
            repo-add -q -R "$out/mobius.db.tar.zst" "$f"; added=1
            echo "   added to the database: $entry"
        fi
    done < <(cd "$1" && PKGDEST="$out" makepkg --packagelist)
    (( added )) && sudo pacman -Sy --noconfirm >/dev/null
    return 0
}

build_dir() {       # $1 = dir with PKGBUILD
    local d="$1" name; name="$(basename "$d")"
    if [[ " ${SKIP_PKGS:-} " == *" $name "* ]]; then echo "== $name: skipped (SKIP_PKGS)"; return; fi
    if already_built "$d"; then echo "== $name: up to date"; register_built "$d"; return; fi
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

# Every Mobius default config that ever shipped, by hash: mobius-skel-sync uses this to tell an old
# default (safe to update) from a file the user edited. Needs git history (CI: fetch-depth 0).
skel_history() {
    local dest="$work/mobius-desktop/files/usr/share/mobius/skel-history.txt" c f rel
    git -C "$root" rev-parse --is-shallow-repository 2>/dev/null | grep -q false || { echo "(no git history: skel-history skipped)"; return 0; }
    mkdir -p "$(dirname "$dest")"; : > "$dest"
    for c in $(git -C "$root" log --format=%H -- packages/mobius-desktop/files/etc/skel/.config); do
        while read -r f; do
            rel="${f#packages/mobius-desktop/files/etc/skel/.config/}"
            echo "$(git -C "$root" show "$c:$f" | sha256sum | cut -d' ' -f1)  $rel"
        done < <(git -C "$root" ls-tree -r --name-only "$c" -- packages/mobius-desktop/files/etc/skel/.config)
    done | sort -u > "$dest"
    echo "skel-history: $(wc -l < "$dest") known default versions"
}
[[ -d "$work/mobius-desktop" ]] && skel_history

# AUR packages first (mobius-settings and mobius-base depend on some of them)
while read -r name commit; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    d="$work/aur/$name"
    if [[ ! -d "$d/.git" ]]; then git clone -q "https://aur.archlinux.org/$name.git" "$d"; fi
    git -C "$d" fetch -q origin && git -C "$d" checkout -q --force "$commit"
    # GitHub release assets can't hold ':' so epoch'd filenames (1:foo) would 404. Drop the epoch.
    sed -i '/^epoch=/d' "$d/PKGBUILD"
    # Our fix for a broken AUR package: packages/aur-fixes/<name>.sh is appended to its PKGBUILD,
    # and pkgrel gets ".1" so the fixed build is newer than the unfixed one with the same version.
    if [[ -f "$root/packages/aur-fixes/$name.sh" ]]; then
        sed -i -E 's/^pkgrel=([0-9]+)$/pkgrel=\1.1/' "$d/PKGBUILD"
        cat "$root/packages/aur-fixes/$name.sh" >> "$d/PKGBUILD"
    fi
    build_dir "$d"
done < "$root/packages/aur.list"

for p in "${MOBIUS_LOCAL_PKGS[@]}"; do build_dir "$work/$p"; done

# Signing. With the key: every package without a signature gets one, and the database files are
# re-signed (they change every run). Without it, nothing is signed (the repo stays unsigned).
if [[ -n "${MOBIUS_SIGNING_KEY:-}" ]]; then
    export GNUPGHOME="$work/gnupg"; rm -rf "$GNUPGHOME"; mkdir -m700 "$GNUPGHOME"
    gpg --batch --quiet --import <<<"$MOBIUS_SIGNING_KEY"
    fpr="$(gpg --batch --list-secret-keys --with-colons | awk -F: '/^fpr/{print $10; exit}')"
    sign() { gpg --batch --yes --quiet --pinentry-mode loopback --passphrase '' -u "$fpr" --detach-sign --no-armor "$1"; }
    n=0
    for f in "$out"/*.pkg.tar.zst; do [[ -f "$f.sig" ]] || { sign "$f"; n=$((n+1)); }; done
    for f in mobius.db mobius.db.tar.zst mobius.files mobius.files.tar.zst; do
        [[ -e "$out/$f" ]] || continue
        [[ -L "$out/$f" ]] && cp --remove-destination "$(readlink -f "$out/$f")" "$out/$f"   # releases can't hold symlinks
        sign "$out/$f"
    done
    echo "signed $n new package(s) and the database with $fpr"
    rm -rf "$GNUPGHOME"
fi

echo "Repo ready: $out"
ls -1 "$out" | grep -c '\.pkg\.tar\.zst$' | xargs echo "packages:"
# KEEP_GOING: everything else was built and is in the repo, but the run still reports failure
if (( ${#failed[@]} )); then echo "FAILED: ${failed[*]}"; exit 1; fi
