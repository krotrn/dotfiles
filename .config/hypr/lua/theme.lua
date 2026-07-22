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
hl.config({
    general = {
        gaps_in    = 2,
        gaps_out   = 2,
        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(21215fff)", "rgba(21215fff)"}, angle = 45 },
            inactive_border = { colors = {"rgba(070722cc)", "rgba(070722cc)"}, angle = 45 },
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },
})

-- ── Decoration ───────────────────────────────────────────────────
hl.config({
    decoration = {
        rounding           = 15,
        active_opacity     = 1.0,
        inactive_opacity   = 0.90,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled = true,
        },

        blur = {
            enabled          = true,
            size             = 1,
            passes           = 3,
            new_optimizations = true,
            ignore_opacity   = true,
            xray             = false,
            special          = true,
        },
    },
})

-- ── Group ────────────────────────────────────────────────────────
hl.config({
    group = {
        col = {
            border_active        = { colors = {"rgba(21215fff)", "rgba(21215fff)"}, angle = 45 },
            border_inactive      = { colors = {"rgba(070722cc)", "rgba(070722cc)"}, angle = 45 },
            border_locked_active = { colors = {"rgba(21215fff)", "rgba(21215fff)"}, angle = 45 },
            border_locked_inactive = { colors = {"rgba(070722cc)", "rgba(070722cc)"}, angle = 45 },
        },
    },
})
