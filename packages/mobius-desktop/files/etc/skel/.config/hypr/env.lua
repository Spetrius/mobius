-- Environment. Without UWSM, Hyprland itself is the session, so set what UWSM used to.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Native Wayland for toolkits that support it, X11 fallback for the rest
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland,x11")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")   -- Discord, Claude Desktop, other Electron apps
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- AMD: RADV only (never amdvlk)
hl.env("AMD_VULKAN_ICD", "RADV")

-- NVIDIA. In hybrid mode (laptop in "Hybrid"/"Auto" in the BIOS) the Intel GPU drives the
-- desktop and games pick the NVIDIA GPU themselves (or use: prime-run %command%), so nothing
-- is set. These are needed when NVIDIA drives the screens: a laptop with the MUX set to "dGPU",
-- or a desktop card like the lab PCs' Quadro P2000 (even if the Intel iGPU is also enabled).
local function read(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local v = f:read("*l"); f:close()
    return v
end
local function nvidia_drives_screens()
    local kinds = { "DP", "HDMI-A", "DVI-D", "DVI-I", "eDP" }
    for card = 0, 7 do
        if (read("/sys/class/drm/card" .. card .. "/device/vendor") or ""):lower() == "0x10de" then
            for _, kind in ipairs(kinds) do
                for n = 1, 8 do
                    if read("/sys/class/drm/card" .. card .. "-" .. kind .. "-" .. n .. "/status") == "connected" then
                        return true
                    end
                end
            end
        end
    end
    return false
end
if nvidia_drives_screens() then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end
