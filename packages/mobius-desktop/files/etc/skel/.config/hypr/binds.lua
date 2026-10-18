-- Keybinds. Same muscle memory as the old CachyOS setup.
local mod = "SUPER"
local terminal    = "alacritty"
local fileManager = "thunar"
local launcher    = "fuzzel"

local function bind(keys, dsp, opts) hl.bind(keys, dsp, opts) end

bind(mod .. " + SPACE",  hl.dsp.exec_cmd(launcher),    { desc = "App launcher" })
bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal),    { desc = "Terminal" })
bind(mod .. " + E",      hl.dsp.exec_cmd(fileManager), { desc = "Files" })
bind(mod .. " + Q",      hl.dsp.window.close(),        { desc = "Close window" })
bind(mod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
bind(mod .. " + F",      hl.dsp.window.fullscreen())
bind(mod .. " + P",      hl.dsp.window.pseudo())
bind(mod .. " + J",      hl.dsp.layout("togglesplit"))
bind(mod .. " + L",      hl.dsp.exec_cmd("hyprlock"),  { desc = "Lock" })
bind(mod .. " + SHIFT + E", hl.dsp.exit(),             { desc = "Log out" })
bind(mod .. " + C",      hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"), { desc = "Clipboard history" })

-- Screenshots: region to clipboard, full screen to ~/Pictures/Screenshots
bind("PRINT",            hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
bind("SHIFT + PRINT",    hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && grim ~/Pictures/Screenshots/$(date +%F_%H-%M-%S).png"))

-- Focus
bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces: Super+N switch, Super+Shift+N move window there
for i = 1, 10 do
    local key = i % 10
    bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end
bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
bind(mod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse move/resize
bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
