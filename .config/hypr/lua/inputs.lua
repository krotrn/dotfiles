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



-- 3-finger swipe left/right switches workspace. Swiping past the last
-- workspace creates a new empty one (workspace_swipe_create_new).
hl.config({
    gestures = {
        workspace_swipe_create_new = true,
        workspace_swipe_distance   = 300,   -- px of swipe for a full switch
        workspace_swipe_cancel_ratio = 0.3, -- release before 30% to snap back
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
