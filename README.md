# Mobius Linux

A personal Arch-based distro for `spetlin` (Ryzen 7 5800X3D, RX 9060 XT). It does everything the old CachyOS install did, but every piece is ours: our kernel build, our tuning package, our Hyprland config, our installer, our package repo.

Built on plain Arch Linux. No CachyOS repos. CachyOS's kernel patchset and system tweaks are borrowed as source (they're GPL) and built here.

## What's in it

| Layer | What Mobius uses |
|---|---|
| Kernel | `linux-mobius`: CachyOS patchset + BORE scheduler, built x86-64-v3 (right for Zen 3), -O3, 1000 Hz, full preempt |
| Tuning | `mobius-settings`: CachyOS sysctl / zram / udev / I/O scheduler / systemd defaults, ananicy-cpp rules, ntsync, plus the **boot guard** |
| Boot | Limine + btrfs + snapper, snapshot entries in the boot menu (limine-snapper-sync), same recovery path that saved you on Sep 29 |
| Desktop | Hyprland 0.56 with a Lua config written for this machine, **no UWSM**, greetd + tuigreet login, Waybar, Mako, Fuzzel, Alacritty, fish |
| Gaming | Steam, GE-Proton (packaged in our repo), Lutris, Wine Staging, umu, protontricks, GameMode, MangoHud, gamescope, RADV only, LACT, amdgpu_top |
| Claude | Claude Code CLI and Claude Desktop, both repacked from Anthropic's official builds, updated through pacman |

### Things it fixes from the old setup
- **Boot guard.** pacman refuses to touch kernels if `/boot` isn't mounted, and after every update it checks that each kernel really landed on the EFI partition. That's the Sep 29 failure, blocked automatically.
- **`mobius-update`** does the safe update routine for you: check `/boot`, full `-Syu`, AUR updates, verify kernels, tell you if a reboot is needed.
- **Monitors switch themselves.** One config with both desks; it picks home (OMEN + Acer) or Dad's (MSI + LG) from the monitors it sees. Override: `mobius-monitors home`, `mobius-monitors dad`, `mobius-monitors auto`.
- **Claude Desktop on monitor 2** at login (window class `com.anthropic.Claude`).
- **Wallpaper works.** `swww` was renamed `awww`; the old `awww-daemom` line was just a typo.
- Game and data drives (GAMES, DATA1, DATA2) are found by label and mounted with `nofail`, so a missing drive never blocks boot.

## Layout

```
packages/            our packages (each a PKGBUILD)
  linux-mobius/        kernel; regenerate from upstream with sync-upstream.sh
  mobius-settings/     system tuning + boot guard + mobius-update
  mobius-desktop/      Hyprland/Waybar/etc. defaults in /etc/skel, greetd config
  mobius-gaming/       meta package: the gaming stack
  mobius-base/         meta package: base system, boot, tools, Claude
  claude-code/         Claude Code CLI (update.sh bumps it)
  claude-desktop/      Claude Desktop (update.sh verifies Anthropic's signed apt index)
  aur.list             AUR packages we rebuild into our repo, pinned by commit
installer/mobius-install   the installer that runs from the ISO
build/
  build-repo.sh        build every package into a pacman repo
  build-iso.sh         build the installer ISO
  bump-aur.sh          move pinned AUR packages to their latest commit
.github/workflows/build.yml   builds and publishes repo + ISO on GitHub
```

## Building

On any Arch machine (your current CachyOS box works):

```
sudo pacman -S --needed archiso base-devel git
git clone <this repo> ~/mobius
cd ~/mobius
build/build-repo.sh            # 1-3 hours the first time (kernel); later runs skip unchanged packages
                               # the kernel build needs about 30 GB of free disk while it runs
sudo build/build-iso.sh        # writes out/iso/mobius-*.iso
```

Or let GitHub build it: Actions tab, `build`, Run workflow. The repo is published as the `repo` release and the ISO as `iso-<date>`.

## Installing

1. Write the ISO to a USB stick, boot it (UEFI).
2. Practice first: `mobius-install --dry-run`
3. Then `mobius-install`.

Two modes:
- **fresh**: wipes one whole disk. Asks you to type the disk's serial number before touching anything.
- **reuse**: installs onto your existing SSD's EFI + btrfs partitions. **Your `@home` is kept**, the old CachyOS root is renamed `@-old-<date>` (not deleted), the EFI partition is reformatted.

The installer refuses to touch any disk holding GAMES, DATA1, DATA2, External HD 1 or External HD 2.

After a **reuse** install your old dotfiles are still in place, so you'll still have the CachyOS Hyprland config. To switch to the Mobius one (your old config is backed up, not deleted):

```
mobius-skel-sync --force
```

## Everyday commands

| Command | Does |
|---|---|
| `mobius-update` (or `up` in fish) | safe full system update |
| `mobius-monitors home/dad/auto` | monitor profile |
| `mobius-skel-sync` | copy any Mobius default configs you don't have yet |
| `limine-snapper-list` | list bootable snapshots |
| `sudo limine-snapper-restore` | roll back after booting a snapshot |
| `game-performance %command%` | Steam launch option: performance power profile while the game runs |

## Status

See [docs/STATUS.md](docs/STATUS.md) for what has been built and tested so far, and what hasn't.
