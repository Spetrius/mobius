-- Mobius Hyprland config. Entry point; each concern lives in its own module.
-- Reload after edits: hyprctl reload   Errors: ~/.local/share/hyprland/hyprland.log
-- Personal overrides go in local.lua (created empty, never overwritten by updates).

require("env")
require("monitors")
require("look")
require("input")
require("binds")
require("rules")
require("autostart")

local ok, err = pcall(require, "local")
if not ok and not tostring(err):find("module 'local' not found", 1, true) then
    hl.notification.create({ text = "local.lua: " .. tostring(err), timeout = 8000 })
end
