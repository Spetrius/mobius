# Mobius status

What has actually been built and tested, and what hasn't. Updated 2026-10-19.

All testing so far happened in a cloud sandbox (Ubuntu host, Arch chroot, QEMU without KVM). Nothing has run on `spetlin` yet.

## Verified

| Item | How |
|---|---|
| All 13 Mobius-repo packages build | `build/build-repo.sh` in a clean Arch environment |
| `linux-mobius` 7.2.11 | Full build. Checked config: BORE, x86-64-v3, 1000 Hz, full preempt, -O3, sched-ext, ntsync, BTF all on. Release string `7.2.11-1-mobius` |
| Hyprland Lua config | `Hyprland --verify-config` on Hyprland 0.56.2 reports `config ok` (and the checker does catch bad fields, tested) |
| Claude Desktop updater | Verifies Anthropic's key fingerprint, signed InRelease, Packages hash, then pins the .deb sha256 |
| Every dependency name | Resolved against live Arch repos (several lib32 packages turned out to be gone from multilib and were removed) |
| Installer safety rails | On a scratch disk: refuses a disk labeled GAMES, refuses `External HD 1` (label with spaces), refuses a mounted disk, refuses a wrong serial confirmation, leaves the disk untouched every time |
| ISO | Builds (1.5 GB, under GitHub's 2 GB release limit), boots in UEFI to the Mobius prompt. Mobius packages are downloaded from the published `repo` release during install |
| GitHub build | The Actions workflow builds every package including the kernel (about 2.5 h) and publishes the pacman repo; pacman installs from it |
| Installer, fresh mode, UEFI | Full run in a VM, no test shortcuts: partitioning, btrfs subvolumes, 992 packages (Steam, Wine, Lutris, LibreOffice...), user, services, snapper, Limine registered in UEFI NVRAM |
| Installer, reuse mode | VM, over a real Mobius install: kept `@home` (marker file intact, same owner), kept the old root as `@-old-<date>` with its snapshots, new system boots with nothing failed |
| Installed system boots | Limine (via its UEFI entry), linux-mobius kernel, greetd/tuigreet login, Hyprland session with Waybar, wallpaper and autostart |

## Bugs the tests caught (all fixed)
- Installer silently exited when looking up the serial of a whole disk.
- Label check relied on udev; now reads labels straight from disk with `blkid`.
- Boot guard treated vfat's `errors=remount-ro` as "read-only" and **would have blocked every kernel update**.
- Installer exited when the GAMES/DATA drives weren't connected.
- GE-Proton's epoch (`1:`) would have produced a filename GitHub releases can't host.
- Boot guard accepted any matching kernel copy on the ESP; now it checks the exact files `limine.conf` boots.
- limine-snapper-sync was missing `inotify-tools` for its watcher (snapshot entries still worked via the snapper plugin).
- Waybar icons were lost from the config file; now written as `\u` escapes.
- Installer reported exit code 1 after a successful fresh install.
- Installer **quit silently on any disk with an ordinary partition label** (it would have hit your CachyOS SSD in reuse mode).
- A failed install left the target mounted, which blocked a retry; the installer now cleans it up.
- One stalled Arch mirror aborted the whole install; the package step now retries up to 3 times (seen working in the VM).
- Repo reachability check used a HEAD request, which GitHub's download links reject.

## Not yet verified
- **reuse mode over CachyOS specifically**: tested over a Mobius install in a VM, not over CachyOS's layout. Run `mobius-install --dry-run` first on the real machine.
- **Installed on spetlin (2026-10-20)**: reuse mode over CachyOS worked, desktop and autostart came up. Helldivers 2 crashed mid-mission on Proton Experimental (STATUS_INVALID_HANDLE); GE-Proton being tested.
- **Hyprland 0.56 `hyprctl dispatch` takes Lua**: hypridle's `dpms off` line was silently broken; fixed to `hl.dsp.dpms({ action = "off" })` (confirmed working on spetlin).
- **Anything on real hardware**: RX 9060 XT under linux-mobius, monitor auto-detection by EDID name, Waybar GPU module, Steam/Proton games, Claude Desktop sign-in with the keyring.
- Package signing: the `[mobius]` repo is unsigned (`SigLevel = Optional TrustAll`). Fine while it's only you, worth fixing before anyone else uses it.

## End-to-end VM test (2026-10-19)
QEMU, UEFI (OVMF), 4 vCPU emulated, 30 GB disk. Booted the Mobius ISO and ran `mobius-install` in fresh mode exactly as you would. Then rebooted into the installed disk:

- Boots through Limine into `7.2.11-1-mobius`, `/etc/os-release` says Mobius Linux, root is `/dev/vda2[/@]`
- `systemctl --failed`: nothing failed
- Active: greetd, NetworkManager, ananicy-cpp, systemd-oomd, power-profiles-daemon, tailscaled
- zram swap active, `ntsync` module loaded, `claude --version` = 2.1.292
- Snapper took a timeline snapshot and it appeared in `limine.conf` under Snapshots (booting a snapshot was not tested)
- Logged in through tuigreet, Hyprland started: Mobius wallpaper, Waybar, Discord autostarted
- Boot guard `post` check passes on the installed system

Note: the VM needed `-cpu max`. linux-mobius is built for x86-64-v3 (AVX2), which your 5800X3D (and the i9-14900HX laptop) support, but very old CPUs and default emulated CPUs don't. A machine without AVX2 shows a black screen after Limine.
