-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                     HYPRBARS (TITLE BARS)                      ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Title bars on floating windows only; tiled windows stay edge-to-edge.
-- See: https://github.com/hyprwm/hyprland-plugins/tree/main/hyprbars
--
-- Guard: only configure when the plugin is loaded (prevents "unknown
-- config key" errors before hyprpm has loaded it at startup).

if hl.plugin.hyprbars == nil then
    return
end

local colors = require("palette").colors

-- Button actions run as shell commands, so they go through hyprctl.
local function dispatch(lua)
    return "hyprctl dispatch '" .. lua .. "'"
end

local toggle_maximize   = dispatch('hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })')
-- Tiling the window drops it into the layout like a freshly opened app;
-- the bar goes away with it (no_bar on tiled windows below).
local tile              = dispatch('hl.dsp.window.float({ action = "toggle" })')

hl.config({
    plugin = {
        hyprbars = {
            bar_height            = 26,
            bar_color             = colors.surface,
            ["col.text"]          = colors.on_surface,
            bar_text_font         = "Inter",
            bar_text_size         = 10,
            bar_text_weight       = 500,
            bar_text_align        = "left",
            bar_padding           = 10,
            bar_button_padding    = 7,
            bar_buttons_alignment = "right",
            icon_on_hover         = true,   -- plain dots until hovered
            on_double_click       = tile,
        },
    },
})

-- Buttons are laid out right to left: close is the rightmost.
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(ff5f57)",
    fg_color = "rgb(4d0000)",
    size     = 12,
    icon     = "×",
    action   = dispatch("hl.dsp.window.close()"),
})
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(28c840)",
    fg_color = "rgb(003a00)",
    size     = 12,
    icon     = "+",
    action   = toggle_maximize,
})
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(febc2e)",
    fg_color = "rgb(5a3d00)",
    size     = 12,
    icon     = "−",
    action   = dispatch('hl.dsp.window.move({ workspace = "special:scratch", follow = false })'),
})

-- Dynamic rules: the bar appears/disappears as a window is floated/tiled.
hl.window_rule({ match = { float = false }, ["hyprbars:no_bar"] = true })
hl.window_rule({ match = { tag = "picture-in-picture" }, ["hyprbars:no_bar"] = true })
