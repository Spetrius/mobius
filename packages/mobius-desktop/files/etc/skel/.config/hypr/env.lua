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
