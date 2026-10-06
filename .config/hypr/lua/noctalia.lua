-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    NOCTALIA v5 INTEGRATION                     ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Noctalia color theming and compositor integration
-- See: https://docs.noctalia.dev/v5/compositor-settings/hyprland/

-- Border/group colors are applied by the generated ../noctalia.lua
-- (require("noctalia").apply_theme() in hyprland.lua), so they follow
-- Noctalia's palette automatically. Don't hardcode them here.

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
