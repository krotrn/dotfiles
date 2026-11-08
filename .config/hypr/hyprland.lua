-- ╔══════════════════════════════════════════════════════════════════╗
-- ║              HYPRLAND v0.57+ LUA CONFIGURATION                 ║
-- ║                  Hyprland v0.57 + glyph shell                  ║
-- ╚══════════════════════════════════════════════════════════════════╝
--
-- Main entry point. Modules are loaded in dependency order.
-- Each module is a self-contained Lua file under lua/.
--
-- To add/remove a module, simply comment/uncomment the require line.
-- Hyprland no longer reads .conf; the remaining .conf file belongs to
-- hypridle.

-- ── Load Modules ─────────────────────────────────────────────────
local modules = {
    "lua.monitors",
    "lua.startup",
    "lua.inputs",
    "lua.theme",
    "lua.animations",
    "lua.keybinds",
    "lua.windowrules",
    "lua.hyprbars"
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
        bell_sound              = "none",  -- app/terminal bells stay silent
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


-- ── Permissions ──────────────────────────────────────────────────
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

-- ── Hymission Plugin (Mission Control Overview) ─────────────────
-- https://github.com/gfhdhytghd/hymission
-- Guard: only apply plugin config if hymission is loaded (prevents
-- "unknown config key" error banner when plugin hasn't been loaded yet)
if hl.plugin.hymission ~= nil then
    -- Overview colors follow palette.lua: "rgb(rrggbb)" + alpha.
    local palette = require("palette").colors
    local function rgba(color, alpha)
        return "rgba(" .. color:match("%x%x%x%x%x%x") .. alpha .. ")"
    end

    hl.config({
        plugin = {
            hymission = {
                -- Layout. The search header is reserved automatically above
                -- outer_padding_top, so 32 is the real gap below it.
                outer_padding_top    = 32,
                outer_padding_right  = 32,
                outer_padding_bottom = 32,
                outer_padding_left   = 32,
                row_spacing          = 32,
                column_spacing       = 32,
                min_window_length    = 120,
                max_preview_scale    = 0.95,
                -- Many windows across workspaces read best as a grid; a single
                -- workspace keeps its real arrangement (natural engine).
                layout_engine                      = "grid",
                layout_engine_onlycurrentworkspace = "natural",

                -- Behavior
                selected_expand_scale             = 1.18,
                hover_expand_scale                = 1.18,
                overview_focus_follows_mouse      = 1,
                multi_workspace_sort_recent_first = 1,
                toggle_switch_mode                = 1,
                switch_toggle_auto_next           = 1,
                switch_release_key                = "Super_L",
                workspace_change_keeps_overview   = 1,
                show_special                      = 1,   -- include the open scratchpad
                -- Hover enlarge uses the "bouncy" spring from animations.lua.
                hover_relayout_animation          = "windowsMove",

                -- Tab groups: one preview per group with clickable member tabs.
                grouped_windows_policy           = "collapsed",
                grouped_windows_collapsed_labels = 1,
                grouped_windows_collapsed_scroll = 1,

                -- Keyboard: each preview gets a key under its physical position;
                -- hitting it jumps straight to the window. "/" starts a search.
                pick_labels_enabled         = 1,
                pick_labels_mode            = "spatial",
                pick_labels_direct_activate = 1,

                -- Preview chrome
                close_button_enabled     = 1,
                close_button_color       = rgba(palette.surface, "eb"),
                close_button_hover_color = rgba(palette.error, "f2"),
                close_button_glyph_color = rgba(palette.on_surface, "fa"),
                show_focus_indicator     = 1,
                focus_hover_color        = rgba(palette.on_surface, "8c"),
                focus_selected_color     = rgba(palette.primary, "f2"),
                focus_title_color        = rgba(palette.on_surface, "ff"),
                focus_hover_thickness    = 2,
                focus_selected_thickness = 3,

                -- Backdrop: none (blur behind the shell layers stalls the GPU).
                backdrop_blur  = 0,
                backdrop_color = "rgba(00000000)",

                -- Workspace strip: shown in every scope so windows can be
                -- dragged between workspaces from the all-workspaces view too.
                workspace_strip_anchor            = "left",
                workspace_strip_empty_mode        = "continuous",
                workspace_strip_force_show        = 1,
                workspace_strip_thickness         = 160,
                workspace_strip_gap               = 24,
                workspace_strip_active_tint_color = rgba(palette.primary, "1a"),
                hide_bar_when_strip               = 1,
                hide_bar_animation                = 1,
                hide_hyprbars_during_overview     = 1,

                -- Workspace tiles: up to three side-by-side workspaces per
                -- monitor (binds in keybinds.lua).
                tiles_enabled  = 1,
                tile_min_width = 240,

                -- Stage: a sidebar of live inactive-workspace cards, toggled
                -- at runtime (Super+comma / Super + 4-finger swipe).
                stage_enabled      = 0,
                stage_empty_slots  = 5,
                stage_drag_reorder = 1,
            },
        },
    })
end

-- ── Shell layers and colors (loaded last to override colors) ─────
package.loaded["lua.layers"] = nil
require("lua.layers")

package.loaded["palette"] = nil
require("palette").apply_theme()
