# CLAUDE.md: Mobius Linux

Personal Arch-based distro for one machine: `spetlin` (Ryzen 7 5800X3D, RX 9060 XT 16GB RDNA4, MSI X470, 32GB). Owner: `spetrius`. See README.md for the user-facing overview and docs/STATUS.md for what is verified.

## Working with the owner
- Shell is **fish**. For commands the owner types: `env VAR=value cmd`, loops end with `end`, no heredocs.
- The owner **cannot type pipe characters** and cannot paste into nano. Hand-run file edits must be a single `python3 -c` (or a short Python script). Pipes are fine in commands Claude runs itself.
- Exact commands, full paths, terse answers. No em-dashes, no section symbols.
- Never partial upgrades. Use `mobius-update`.
- Bootloader, partitioning, fstab and `/etc` changes on the live machine stay with the owner.

## Design decisions (settled, don't relitigate)
- Base: plain Arch + multilib + our `[mobius]` repo. **No CachyOS repos.** CachyOS kernel patches and settings are used as source only.
- Kernel: `linux-mobius` = CachyOS `linux-cachyos-bore` PKGBUILD with pkgbase renamed, `_processor_opt=generic_v3`, compressed debug info. Never edit `packages/linux-mobius/PKGBUILD` by hand: change `sync-upstream.sh` and rerun it.
- Hyprland 0.56 uses **Lua config natively** (hyprland.conf is the legacy path). Our config is in `packages/mobius-desktop/files/etc/skel/.config/hypr/*.lua`. **No UWSM**: autostart lives in `autostart.lua` (`hl.on("hyprland.start", ...)`), login is greetd + tuigreet running `start-hyprland`.
- Workspace 1 = DP-2 (main), workspace 2 = HDMI-A-1 (side) at both desks. Monitor profile auto-detects by EDID description in `monitors.lua`.
- Boot: Limine via `limine-mkinitcpio-hook` (limine-entry-tool) + `limine-snapper-sync`. Kernels live under `/boot/<machine-id>/...`, cmdline in `/etc/default/limine`. Snapper uses the nested `@/.snapshots` layout.
- Boot guard (`mobius-settings`): pre-transaction hook aborts kernel/initramfs/microcode changes if `/boot` is not a mounted vfat; post-transaction checks each kernel by sha256 on `/boot`.
- Repo hosting: GitHub release `repo` on this repository. Release assets can't contain `:`, so `build-repo.sh` strips `epoch=` from AUR PKGBUILDs.
- Claude Desktop: repack of Anthropic's official .deb. `update.sh` verifies key `31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE` -> signed InRelease -> Packages -> .deb. Claude Code: native binary, auto-updater disabled via `/etc/claude-code/managed-settings.json`.
- protonup-qt was dropped (pulled a chain of AUR Python libs); GE-Proton comes from our repo, Lutris manages its own runners.

## Layout
- `packages/<name>/PKGBUILD` (+ `files/` tree copied verbatim into the package)
- `packages/aur.list`: AUR packages rebuilt into our repo, `name commit`, in dependency order
- `build/config.sh`: GitHub owner/repo, package build order
- `build/build-repo.sh`: builds everything into `out/repo`, skips packages whose exact version already exists. `SKIP_PKGS=`, `KEEP_GOING=1`.
- `build/build-iso.sh`: releng profile + installer + offline copy of the repo
- `installer/mobius-install`: `fresh` / `reuse` modes, `--dry-run`, unattended via `MOBIUS_*` env vars

## Rules when changing things
- Bump `pkgrel` (or `pkgver`) of any package you change, or `build-repo.sh` will treat it as already built.
- New package that others depend on: add it to `MOBIUS_LOCAL_PKGS` (in order) or `aur.list` (in order).
- Validate dependency names against the real repos (`pacman -Si`) before committing; multilib has dropped several lib32 packages.
- Protected labels in the installer (GAMES, DATA1, DATA2, External HD 1/2) must never be removed.
