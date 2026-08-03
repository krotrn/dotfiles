-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              HYPRLAND v0.56+ LUA CONFIGURATION                 ║
-- ║          Compatible with Hyprland v0.56 & Noctalia v5          ║
-- ╚══════════════════════════════════════════════════════════════════╝
--
-- Main entry point. Modules are loaded in dependency order.
-- Each module is a self-contained Lua file under lua/.
--
-- To add/remove a module, simply comment/uncomment the require line.
-- The old .conf files are preserved alongside for reference.

-- ── Load Modules ─────────────────────────────────────────────────
-- ── Load Modules ─────────────────────────────────────────────────
local modules = {
    "lua.monitors",
    "lua.startup",
    "lua.inputs",
    "lua.theme",
    "lua.animations",
    "lua.hyprlock",
    "lua.keybinds",
    "lua.windowrules"
}

for _, mod in ipairs(modules) do
    package.loaded[mod] = nil
    require(mod)
end

-- ── Layouts ──────────────────────────────────────────────────────
hl.config({
    dwindle = {
        preserve_split    = true,
        smart_resizing    = true,
        force_split       = 0,
    },
    master = {
        new_status = "master",
        mfact        = 0.55,
        orientation  = "left",
    },
})

-- ── Misc ─────────────────────────────────────────────────────────
hl.config({
    misc = {
        vrr                      = 0,       -- 0=OFF  1=ON  2=FULLSCREEN ONLY
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        anr_missed_pings         = 5,
        allow_session_lock_restore = true,
    },
})

-- ── XWayland ─────────────────────────────────────────────────────
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- ── Cursor ───────────────────────────────────────────────────────
hl.config({
    cursor = {
        inactive_timeout  = 5,
        no_warps          = false,
        enable_hyprcursor = true,
    },
})

-- ── Snap (floating window snapping) ──────────────────────────────
hl.config({
    general = {
        snap = {
            enabled = true,
        },
        gaps_in = 1,
        gaps_out = 1,
        border_size = 0,
    },
})

-- ── Permissions ──────────────────────────────────────────────────
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-- ── Hymission Plugin (Mission Control Overview) ─────────────────
-- https://github.com/gfhdhytghd/hymission
-- Guard: only apply plugin config if hymission is loaded (prevents
-- "unknown config key" error banner when plugin hasn't been loaded yet)
if hl.plugin.hymission ~= nil then
    hl.config({
        plugin = {
            hymission = {
                -- Layout
                outer_padding_top    = 92,
                outer_padding_right  = 32,
                outer_padding_bottom = 32,
                outer_padding_left   = 32,
                row_spacing          = 32,
                column_spacing       = 32,
                min_window_length    = 120,
                layout_engine        = "grid",
                max_preview_scale    = 0.95,

                -- Behavior
                expand_selected_window         = 1,
                hover_expand_scale             = 1.18,
                overview_focus_follows_mouse   = 1,
                multi_workspace_sort_recent_first = 1,
                toggle_switch_mode             = 1,
                switch_toggle_auto_next        = 1,
                switch_release_key             = "Super_L",
                workspace_change_keeps_overview = 1,

                -- Appearance
                backdrop_blur          = 0,
                backdrop_color         = "rgba(00000000)",
                show_focus_indicator   = 0,
                focus_hover_color      = "rgba(f2f7ff8c)",
                focus_selected_color   = "rgba(3dc7fff2)",
                focus_hover_thickness  = 2,
                focus_selected_thickness = 4,

                -- Workspace strip
                workspace_strip_anchor     = "left",
                workspace_strip_empty_mode = "existing",
                workspace_strip_thickness  = 160,
                workspace_strip_gap        = 24,
                hide_bar_when_strip        = 1,
                hide_bar_animation         = 1,
            },
        },
    })
end

-- ── Noctalia v5 Integration (loaded last to override colors) ─────
package.loaded["lua.noctalia"] = nil
require("lua.noctalia")

-- For Noctalia Color templates
package.loaded["noctalia"] = nil
require("noctalia").apply_theme()
