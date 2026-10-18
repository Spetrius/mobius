-- Look and feel
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(40a0ffee)", "rgba(c060ffee)" }, angle = 45 },
            inactive_border = "rgba(404050aa)",
        },
        resize_on_border = true,
        allow_tearing = true,   -- only applies to windows tagged immediate (games, see rules.lua)
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        rounding_power = 2,
        shadow = { enabled = true, range = 6, render_power = 3, color = 0xee111118 },
        blur = { enabled = true, size = 4, passes = 2, vibrancy = 0.17 },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        vrr = 2,                 -- VRR for fullscreen only
        enable_swallow = true,
        swallow_regex = "^(Alacritty)$",
    },
    render = { direct_scanout = 2 },  -- fullscreen games skip compositing
    cursor = { no_hardware_cursors = false },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",     enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",    enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1,  spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",     enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "quick", style = "slide" })
