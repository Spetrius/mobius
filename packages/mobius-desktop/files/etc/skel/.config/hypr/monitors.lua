-- Two desks and a laptop, one config. The profile is picked from the monitors that are plugged in.
-- Force one with: mobius-monitors home | dad | laptop | auto   (writes ~/.config/hypr/monitor-profile)
-- Monitors are recognised by their EDID name, not by the port they are plugged into, so moving a
-- cable to another port changes nothing. Workspace 1 lives on the main screen, workspace 2 on the
-- side screen. Any other screen at a desk (a TV, a projector) goes far right as workspace 10.

local profiles = {
    home = {
        -- HP OMEN, left
        { match = "OMEN", mode = "2560x1440@75",  position = "0x0",    scale = 1, workspace = "2" },
        -- Acer ultrawide, right, main
        { match = "ACER", mode = "3440x1440@144", position = "2560x0", scale = 1, workspace = "1" },
    },
    dad = {
        -- Samsung S24D590 (24"), left
        { match = "S24D590",   mode = "1920x1080@60",  position = "0x0",    scale = 1, workspace = "3" },
        -- MSI G273, center, main
        { match = "MSI",       mode = "1920x1080@144", position = "1920x0", scale = 1, workspace = "1" },
        -- LG ULTRAGEAR, right
        { match = "ULTRAGEAR", mode = "1920x1080@165", position = "3840x0", scale = 1, workspace = "2" },
    },
    laptop = {
        -- Legion 5i built-in 16" 2560x1600 165 Hz (eDP-2 when the BIOS MUX is set to dGPU)
        { port = "^eDP", mode = "2560x1600@165", position = "0x0", scale = 1.25, workspace = "1" },
    },
}
-- Screens at a desk that match nothing above
local extra = { mode = "preferred", position = "auto-right", scale = 1, workspace = "10" }

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

local function monitors()
    local ok, mons = pcall(hl.get_monitors)
    if ok and mons then return mons end
    return {}
end

local function detect(mons)
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

-- The profile entry for one connected monitor: by EDID name, or by port for the laptop panel
local function entry_for(profile, m)
    local d, port = (m.description or ""):upper(), m.name or ""
    for _, spec in ipairs(profile) do
        if (spec.match and d:find(spec.match, 1, true)) or (spec.port and port:find(spec.port)) then
            return spec
        end
    end
    return nil
end

local placed = {}   -- port -> "mode position workspace" last applied, so re-runs add nothing new
local function place(port, spec)
    local key = spec.mode .. " " .. spec.position .. " " .. spec.workspace
    if placed[port] == key then return end
    placed[port] = key
    hl.monitor({ output = port, mode = spec.mode, position = spec.position, scale = spec.scale })
    hl.workspace_rule({ workspace = spec.workspace, monitor = port, default = true,
                        persistent = spec.workspace ~= extra.workspace })
end

local function apply()
    local mons = monitors()
    local name = forced_profile() or detect(mons)
    -- Monitors that match no profile (e.g. the lab PCs) keep the catch-all rule below
    if not name then return end
    for _, m in ipairs(mons) do
        local port = m.name or ""
        if port ~= "" then
            local spec = entry_for(profiles[name], m)
            if spec then
                place(port, spec)
            elseif not port:find("^eDP") then
                place(port, extra)
            end
        end
    end
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
    local mons = monitors()
    local external = false
    for _, m in ipairs(mons) do
        if not (m.name or ""):find("^eDP") then external = true end
    end
    local spec = profiles.laptop[1]
    for _, port in ipairs({ "eDP-1", "eDP-2" }) do
        if not closed then
            hl.monitor({ output = port, mode = spec.mode, position = spec.position, scale = spec.scale })
        elseif external then
            hl.monitor({ output = port, disabled = true })
        end
    end
end
hl.bind("switch:on:Lid Switch",  function() lid(true) end,  { locked = true })
hl.bind("switch:off:Lid Switch", function() lid(false) end, { locked = true })
