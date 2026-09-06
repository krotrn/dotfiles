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

-- ── Curves (Bézier & Spring) ─────────────────────────────────────
hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("smoothOut", { type = "bezier", points = { { 0.36, 0 }, { 0.66, -0.56 } } })
hl.curve("smoothIn", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

-- Modern Spring physics
hl.curve("bouncy", { type = "spring", mass = 1, stiffness = 85, dampening = 14 })

-- ── Animation Rules ──────────────────────────────────────────────
hl.animation({ leaf = "windows", enabled = true, speed = 5, spring = "bouncy", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "smoothOut", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smoothOut", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, spring = "bouncy" })

hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 40, bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smoothIn" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "wind", style = "slidevert" })

-- ── Layer Animations ─────────────────────────────────────────────
hl.animation({ leaf = "layers",        enabled = true, speed = 4, bezier = "smoothIn",  style = "fade" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4, bezier = "smoothIn",  style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 4, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "fadeLayers",    enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 4, bezier = "smoothOut" })