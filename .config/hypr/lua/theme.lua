-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                           THEME                                ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Visual theming: cursors, gaps, borders, decoration, blur
-- See: https://wiki.hypr.land/Configuring/Basics/Variables/

-- ── Cursor Theme ─────────────────────────────────────────────────
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE",  "24")
hl.env("XCURSOR_THEME",    "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE",     "24")
hl.env("QT_CURSOR_THEME",  "Bibata-Modern-Classic")
hl.env("QT_CURSOR_SIZE",   "24")

-- ── General ──────────────────────────────────────────────────────
-- Edge-to-edge layout: no borders, hairline gaps. Focus is shown by
-- dimming inactive windows (see decoration). Border/group colors come
-- from Noctalia (noctalia.lua), so none are set here.
hl.config({
    general = {
        gaps_in     = 1,
        gaps_out    = 1,
        border_size = 0,

        snap = {
            enabled = true,   -- floating window snapping
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },
})

-- ── Decoration ───────────────────────────────────────────────────
hl.config({
    decoration = {
        rounding           = 0,
        -- Keep every window fully opaque so code/docs in an unfocused
        -- window stay readable. Terminal translucency is handled by the
        -- terminal itself (background only, text stays crisp).
        active_opacity     = 1.0,
        inactive_opacity   = 1.0,
        fullscreen_opacity = 1.0,

        -- Without borders, dimming is the focus indicator.
        dim_inactive       = true,
        dim_strength       = 0.2,
        dim_special        = 0.4,   -- backdrop behind the scratchpad

        shadow = {
            enabled      = true,
            range        = 15,
            render_power = 3,
            color        = "rgba(00000055)",
            offset       = { 0, 2 },
            scale        = 1.0,
        },

        blur = {
            enabled          = true,
            size             = 2,
            passes           = 2,
            new_optimizations = true,
            ignore_opacity   = true,
            xray             = false,
            special          = true,
            popups           = true,
            popups_ignorealpha = 0.2,
        },
    },
})
