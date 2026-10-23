-- Autostart. No UWSM: Hyprland starts these itself, and pushes its environment to
-- systemd/dbus so portals, keyring and user services see WAYLAND_DISPLAY.
-- The sleeps keep the old ordering: Discord maps first and tiles left of Firefox.
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE DISPLAY")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("mobius-wallpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("udiskie --tray")
    hl.exec_cmd("nm-applet --indicator")     -- Wi-Fi/network tray icon
    hl.exec_cmd("blueman-applet")            -- Bluetooth tray icon
    -- Proton VPN in the tray. The delay lets Waybar's tray come up first: the app only
    -- looks for it once. Auto-connect is set in the app: Settings, "Connect at app startup".
    hl.exec_cmd("sh -c 'sleep 3 && protonvpn-app --start-minimized'")
    hl.exec_cmd("wl-paste --watch cliphist store")

    hl.exec_cmd("discord")
    hl.exec_cmd("sh -c 'sleep 5 && steam -silent'")
    hl.exec_cmd("sh -c 'sleep 6 && firefox'")
    hl.exec_cmd("sh -c 'sleep 7 && claude-desktop'")
end)
