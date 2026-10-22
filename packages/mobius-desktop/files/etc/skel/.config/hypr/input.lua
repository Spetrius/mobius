hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",   -- raw mouse for games
        -- Laptop touchpad (ignored on machines without one)
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = true,
        },
    },
})

-- Three-finger swipe left/right switches workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
