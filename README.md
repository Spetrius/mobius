# Mobius Linux

A personal Arch-based distro for `spetlin` (Ryzen 7 5800X3D, RX 9060 XT) and a Lenovo Legion 5i laptop (i9-14900HX, RTX 4060). It does everything the old CachyOS install did, but every piece is ours: our kernel build, our tuning package, our Hyprland config, our installer, our package repo.

Built on plain Arch Linux. No CachyOS repos. CachyOS's kernel patchset and system tweaks are borrowed as source (they're GPL) and built here.

## What's in it

| Layer | What Mobius uses |
|---|---|
| Kernel | `linux-mobius`: CachyOS patchset + BORE scheduler, built x86-64-v3 (right for Zen 3), -O3, 1000 Hz, full preempt |
| Tuning | `mobius-settings`: CachyOS sysctl / zram / udev / I/O scheduler / systemd defaults, ananicy-cpp rules, ntsync, plus the **boot guard** |
| Boot | Limine + btrfs + snapper, snapshot entries in the boot menu (limine-snapper-sync), same recovery path that saved you on Sep 29 |
| Desktop | Hyprland 0.56 with a Lua config written for this machine, **no UWSM**, greetd + tuigreet login, Waybar, Mako, Fuzzel, Alacritty, fish |
| Gaming | Steam, GE-Proton (packaged in our repo), Minecraft Launcher, Lutris, Wine Staging, umu, protontricks, GameMode, MangoHud, gamescope, RADV only, LACT, amdgpu_top |
| Claude | Claude Code CLI and Claude Desktop, both repacked from Anthropic's official builds, updated through pacman |
| VPN | Proton VPN (Arch's `proton-vpn-gtk-app`), starts minimized to the tray at login |
| Firefox | `mobius-firefox`: a toolbar button that makes one site believe you run Windows (the school portal) |
| Apps | `mobius-apps`: KDE Connect (phone link), Syncthing (folder sync), OBS Studio, darktable, RawTherapee, GIMP, gphoto2, Anki, Obsidian, Xournal++, LM Studio (run AI models locally), Bambu Studio (3D printing, P1S + AMS) |

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
  mobius-nvidia/       NVIDIA open driver (DKMS) + PRIME offload, installed only on NVIDIA machines
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

Every build is tested before it is published (`build/test-repo.sh`): all Mobius packages must resolve against current Arch, the default Hyprland config must pass `Hyprland --verify-config`, and every script must parse. If a test fails the repo database is not updated, so no machine ever sees a broken set.

Every Saturday the `bump` workflow syncs the kernel with CachyOS and the pinned AUR packages with the AUR, and opens a pull request (with links to the upstream changes). Merging it is the only step.

## Installing

1. Write the ISO to a USB stick, boot it (UEFI).
2. Practice first: `mobius-install --dry-run`
3. Then `mobius-install`.

Two modes:
- **fresh**: wipes one whole disk. Asks you to type the disk's serial number before touching anything.
- **reuse**: installs onto your existing SSD's EFI + btrfs partitions. **Your `@home` is kept**, the old CachyOS root is renamed `@-old-<date>` (not deleted), the EFI partition is reformatted.

The installer refuses to touch any disk holding GAMES, DATA1, DATA2, External HD 1 or External HD 2.

It also checks the hardware and adds what that machine needs: Intel microcode, thermald and Intel GPU drivers on an Intel CPU, and `mobius-nvidia` on an NVIDIA GPU. The AMD desktop gets nothing extra.

### Laptop (Legion 5i, hybrid graphics)
- Leave the BIOS GPU mode on **Hybrid** (or Auto). The Intel GPU draws the desktop and the RTX 4060 powers off when idle, which is what gives decent battery life.
- Games: Vulkan/DXVK/Proton games normally pick the RTX 4060 by themselves. If one runs on the Intel GPU, set its Steam launch option to `prime-run %command%`.
- The **dGPU** MUX setting also works (Hyprland detects NVIDIA-only and sets the right variables) but battery life is much worse.
- Brightness keys, touchpad (tap to click, natural scroll, 3-finger workspace swipe), battery and backlight in Waybar work out of the box.
- `mobius-battery on` stops charging early (Lenovo conservation mode) so the battery lasts more years on the charger; `mobius-battery off` the night before a trip. Remembered across reboots.
- Closing the lid with an external monitor plugged in turns the built-in screen off instead of sleeping; opening it turns the screen back on.
- `mobius-gpu-check` checks the NVIDIA setup (driver, sleep support, GPU power saving, prime-run) and lists the two things to try by hand.

After a **reuse** install your old dotfiles are still in place, so you'll still have the CachyOS Hyprland config. To switch to the Mobius one (your old config is backed up, not deleted):

```
mobius-skel-sync --force
```

## Everyday commands

| Command | Does |
|---|---|
| `mobius-update` (or `up` in fish) | safe full system update: Arch news first, then update, new config defaults, vulnerability and firmware report |
| `mobius-monitors home/dad/auto` | monitor profile |
| `mobius-skel-sync` | bring configs up to the Mobius defaults; files you edited are kept and listed (`--diff F` / `--take F`). `mobius-update` runs it for you |
| `mobius-backup init` / `now` / `status` / `list` / `browse` / `restore PATH` | nightly encrypted home backup to the DATA1 drive (only ever to a mounted DATA1, never your system drive) |
| `mobius-secureboot` / `sudo mobius-secureboot setup` | Secure Boot status / one-time setup with your own keys (instructions inside: BIOS to Setup Mode first) |
| `mobius-remote host on` (on the desktop, once) / `mobius-remote` (on the laptop) | remote desktop to the desktop PC over Tailscale: full keyboard and mouse, log in with your normal password, Super+Alt+O switches monitor |
| `limine-snapper-list` | list bootable snapshots |
| `sudo limine-snapper-restore` | roll back after booting a snapshot |
| `game-performance %command%` | Steam launch option: performance power profile while the game runs |

## Themes and layouts

Press **Super+T** (or run `mobius-theme`) to switch, live, no update needed:

| Themes | | Layouts | |
|---|---|---|---|
| Mobius Green | deep green, amber bar text | Default | rounded, small gaps, bar on top |
| Cyberdeck | red-on-black HUD, cyan/yellow accents, Rajdhani | Cyberdeck | square, glowing borders, bracketed workspaces |
| Arctic | navy and ice blue | Floating | big gaps, round corners, floating pill bar |
| Ember | charcoal and orange | Compact | no gaps, thin bar at the bottom |

Any theme works with any layout. **Custom color...** in the picker opens a color dialog and builds a whole theme (wallpaper included) around the color you pick. Make your own by copying a file from `/usr/share/mobius/themes` (or `layouts`) to `~/.local/share/mobius/themes` and editing it.

Under the hood each app loads one generated file from `~/.config/mobius/generated` (Hyprland, Waybar, mako, fuzzel, Alacritty, hyprlock, GTK); `mobius-theme` rewrites those and reloads the apps. Wallpapers are drawn from the theme's colors at your screen size. A picture in `~/Pictures/Wallpapers/current.*` still wins over the theme wallpaper.

## Firefox extension

It comes preinstalled for every Firefox profile (`mobius-firefox`, in `/usr/lib/firefox/browser/extensions`). Arch's Firefox allows unsigned extensions there, so no Mozilla account is needed.

**Windows Disguise**: on a site that refuses Linux, click the Windows button in the toolbar. That site (and its subdomains) now sees Windows, the page reloads, and the button shows **WIN**. Click again to turn it off. The list is also under about:addons > Mobius Windows Disguise > Preferences.

## Keys

| Keys | Does |
|---|---|
| Super+Space / Return / E | launcher / terminal / files |
| Super+Escape | power menu |
| Super+T | theme and layout picker |
| Super+Shift+S | region screenshot, opens in satty to mark up |
| Print | region screenshot to clipboard |
| Super+Shift+R | start/stop screen recording (~/Videos/Recordings) |
| Super+Shift+C | color picker, copies the hex code |
| Super+. | emoji picker |
| Super+C | clipboard history |
| Alt+Tab | next window |
| Super+L | lock |

## Status

See [docs/STATUS.md](docs/STATUS.md) for what has been built and tested so far, and what hasn't.
