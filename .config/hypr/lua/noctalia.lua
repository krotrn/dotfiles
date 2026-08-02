-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    NOCTALIA v5 INTEGRATION                     ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Noctalia color theming and compositor integration
-- See: https://docs.noctalia.dev/v5/compositor-settings/hyprland/

-- ── Noctalia Color Palette ───────────────────────────────────────
-- These colors are applied by Noctalia's color template system.
-- If Noctalia regenerates colors, update these values to match.
local colors = {
    primary        = "rgb(58a6ff)",
    surface        = "rgb(010409)",
    secondary      = "rgb(bc8cff)",
    error          = "rgb(f85149)",
    tertiary       = "rgb(bc8cff)",
    surface_lowest = "rgb(05080e)",
}

-- ── Border Colors (Noctalia override) ────────────────────────────
hl.config({
    general = {
        col = {
            active_border   = colors.primary,
            inactive_border = colors.surface,
        },
    },
})

-- ── Group Colors (Noctalia override) ─────────────────────────────
hl.config({
    group = {
        col = {
            border_active        = colors.secondary,
            border_inactive      = colors.surface,
            border_locked_active = colors.error,
            border_locked_inactive = colors.surface,
        },

        groupbar = {
            col = {
                active          = colors.secondary,
                inactive        = colors.surface,
                locked_active   = colors.error,
                locked_inactive = colors.surface,
            },
        },
    },
})

-- ── Noctalia Layer Blur ──────────────────────────────────────────
-- Enable blur on Noctalia surfaces for a polished look
-- Per Noctalia v5 docs: disable Hyprland layer animations for Noctalia
hl.config({
    decoration = {
        blur = {
            enabled = true,
        },
    },
})

-- Disable Hyprland's layer animations for Noctalia surfaces
-- so they don't interfere with Noctalia's own animations
hl.animation({ leaf = "layers", enabled = false })

-- ── Noctalia Layer Rules ─────────────────────────────────────────
-- Disable heavy blur behind animated Noctalia panels/overlays to avoid GPU shader stalls & screen freezes
hl.layer_rule({ match = { namespace = "^noctalia.*$" }, blur = false })
hl.layer_rule({ match = { namespace = "^gtk-layer-shell$" }, blur = false })
