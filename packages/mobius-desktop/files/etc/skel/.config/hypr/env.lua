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
-- is set. Only when NVIDIA is the sole GPU (MUX set to "dGPU") does it need these.
local function gpu_vendors()
    local found = {}
    for i = 0, 7 do
        local f = io.open("/sys/class/drm/card" .. i .. "/device/vendor", "r")
        if f then
            found[(f:read("*l") or ""):lower()] = true
            f:close()
        end
    end
    return found
end
local v = gpu_vendors()
if v["0x10de"] and not v["0x8086"] and not v["0x1002"] then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end
