-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        ANIMATIONS                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Animation curves and window/workspace transitions
-- See: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
    animations = {
        enabled = true,
    },
})

-- ── Bezier Curves ────────────────────────────────────────────────
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

-- ── Animation Rules ──────────────────────────────────────────────
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "once" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "wind" })

-- ── Premium Easing Curves ────────────────────────────────────────
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("smoothIn",  { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

-- ── Layer Animations ─────────────────────────────────────────────
hl.animation({ leaf = "layers",        enabled = true, speed = 3, bezier = "smoothIn",  style = "fade" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3, bezier = "smoothIn",  style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "fadeLayers",    enabled = true, speed = 3, bezier = "smoothIn" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3, bezier = "smoothIn" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3, bezier = "smoothOut" })
