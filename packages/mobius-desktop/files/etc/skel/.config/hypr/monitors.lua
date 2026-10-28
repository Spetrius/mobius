-- Two desks and a laptop, one config. The profile is picked from the monitors that are plugged in.
-- Force one with: mobius-monitors home | dad | laptop | auto   (writes ~/.config/hypr/monitor-profile)
-- Workspace 1 always lives on the main screen (DP-2), workspace 2 on the side screen (HDMI-A-1).

local profiles = {
    home = {
        -- HP OMEN, left
        { output = "HDMI-A-1", mode = "2560x1440@75",  position = "0x0",    scale = 1 },
        -- Acer ultrawide, right, main
        { output = "DP-2",     mode = "3440x1440@144", position = "2560x0", scale = 1 },
    },
    dad = {
        -- MSI G273, left, main
        { output = "DP-2",     mode = "preferred", position = "0x0",    scale = 1 },
        -- LG ULTRAGEAR, right
        { output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = 1 },
    },
    laptop = {
        -- Legion 5i built-in 16" 2560x1600 165 Hz (eDP-2 when the BIOS MUX is set to dGPU)
        { output = "eDP-1", mode = "2560x1600@165", position = "0x0", scale = 1.25 },
        { output = "eDP-2", mode = "2560x1600@165", position = "0x0", scale = 1.25 },
    },
}

-- Substrings of the EDID description (hyprctl monitors shows it as "description")
local signatures = {
    home = { "OMEN", "ACER" },
    dad  = { "MSI", "ULTRAGEAR", "LG ELECTRONICS" },
}

local function forced_profile()
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/monitor-profile", "r")
    if not f then return nil end
    local name = (f:read("*l") or ""):match("^%s*(%a+)%s*$")
    f:close()
    if name and profiles[name] then return name end
    return nil
end

local function detect()
    local ok, mons = pcall(hl.get_monitors)
    if not ok or not mons then return nil end
    local laptop = false
    for _, m in ipairs(mons) do
        if (m.name or ""):find("^eDP") then laptop = true end
        local d = (m.description or ""):upper()
        for name, keys in pairs(signatures) do
            for _, k in ipairs(keys) do
                if d:find(k, 1, true) then return name end
            end
        end
    end
    -- A desk's monitors win; a built-in panel alone means the laptop
    return laptop and "laptop" or nil
end

local current
local function apply()
    local name = forced_profile() or detect() or current or "home"
    if name == current then return end
    current = name
    for _, spec in ipairs(profiles[name]) do hl.monitor(spec) end
end

-- Anything unknown (a TV, a projector) still lights up
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
apply()
hl.on("monitor.added", apply)
hl.on("hyprland.start", apply)

-- Laptop lid: closing it with an external monitor plugged in turns the built-in screen off
-- (logind doesn't suspend while docked); opening it turns the screen back on. With no external
-- monitor, closing the lid suspends as usual.
local function lid(closed)
    local ok, mons = pcall(hl.get_monitors)
    if not ok or not mons then return end
    local external = false
    for _, m in ipairs(mons) do
        if not (m.name or ""):find("^eDP") then external = true end
    end
    for _, spec in ipairs(profiles.laptop) do
        if not closed then
            hl.monitor(spec)
        elseif external then
            hl.monitor({ output = spec.output, disabled = true })
        end
    end
end
hl.bind("switch:on:Lid Switch",  function() lid(true) end,  { locked = true })
hl.bind("switch:off:Lid Switch", function() lid(false) end, { locked = true })

hl.workspace_rule({ workspace = "1", monitor = "DP-2",     default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true, persistent = true })
