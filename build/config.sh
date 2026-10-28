# Shared build settings. GitHub owner/repo where releases host the pacman repo + ISO.
MOBIUS_GH="${MOBIUS_GH:-Spetrius/mobius}"
MOBIUS_REPO_URL="${MOBIUS_REPO_URL:-https://github.com/${MOBIUS_GH}/releases/download/repo}"
# Packages in this repo, in build order (deps first). linux-mobius is slow (1-3 h).
MOBIUS_LOCAL_PKGS=(mobius-settings linux-mobius claude-code claude-desktop mobius-apps mobius-desktop mobius-gaming mobius-nvidia mobius-base)
