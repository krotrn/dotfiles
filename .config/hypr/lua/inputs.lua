-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                          INPUTS                                ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Input devices: keyboard, mouse, touchpad
-- See: https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        -- Keyboard
        kb_layout           = "us",
        -- kb_options      = "grp:win_space_toggle",  -- uncomment for Win+Space layout switching
        numlock_by_default  = true,
        repeat_delay        = 250,
        repeat_rate         = 35,
        accel_profile       = "flat",
        sensitivity         = 0,           -- -1.0 to 1.0, 0 = no modification

        -- Touchpad
        touchpad            = {
            natural_scroll       = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor        = 0.5,
            tap_button_map       = "lrm",  -- 1-finger=left, 2-finger=right, 3-finger=middle
            drag_lock            = true,    -- easier drag without holding finger down
        },

        special_fallthrough = true,
        follow_mouse        = 1,
    },
})



hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "move"
})
