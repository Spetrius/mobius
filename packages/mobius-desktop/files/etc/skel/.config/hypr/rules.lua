-- Window rules. Workspace 1 = main screen (DP-2), workspace 2 = side screen (HDMI-A-1).
local main, side = 1, 2

hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Windows games (Proton/Wine/Lutris): main screen, centered, allowed to tear for lowest latency
hl.window_rule({ name = "wine-games", match = { class = "^(.*\\.exe)$" },
    workspace = main, center = true, immediate = true })
hl.window_rule({ name = "steam-games", match = { class = "^(steam_app_.*)$" },
    workspace = main, immediate = true })
hl.window_rule({ name = "gamescope", match = { class = "^(gamescope)$" },
    workspace = main, immediate = true })

-- Side screen: chat, browser, Claude
hl.window_rule({ name = "discord", match = { class = "^(vesktop|discord)$" },     workspace = side .. " silent" })
hl.window_rule({ name = "browser", match = { class = "^(firefox|zen)$" },        workspace = side .. " silent" })
hl.window_rule({ name = "claude",  match = { class = "^(com\\.anthropic\\.Claude)$" }, workspace = side .. " silent" })

-- Steam main window on the main screen
hl.window_rule({ name = "steam", match = { class = "^(steam)$", title = "^(Steam)$" }, workspace = main .. " silent" })

-- Small utility windows float
hl.window_rule({ name = "float-utils",
    match = { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|nm-connection-editor|blueman-manager|hyprland-run)$" },
    float = true })
