-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        KEYBINDS                                ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- All keyboard and mouse bindings
-- See: https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- Each bind's `description` is what the Super+H cheatsheet shows, and the
-- numbered section headings below become its categories.

local scrPath = os.getenv("HOME") .. "/.config/hypr/Scripts"

-- ── Helper: float-aware move ─────────────────────────────────────
-- Floating windows nudge by pixels; tiled windows swap in the layout.
local function move_active(dx, dy, dir)
    return function()
        local win = hl.get_active_window()
        if win and win.floating then
            hl.dispatch(hl.dsp.window.move({ x = dx, y = dy, relative = true }))
        else
            hl.dispatch(hl.dsp.window.move({ direction = dir }))
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 1. APPLICATIONS
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("wezterm"), { description = "Terminal" })
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "File manager" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("code"), { description = "VS Code" })
hl.bind("SUPER + B", hl.dsp.exec_cmd(scrPath .. "/browser-launcher.sh"), { description = "Browser" })

-- ═══════════════════════════════════════════════════════════════════
-- 2. GLYPH SHELL
-- ═══════════════════════════════════════════════════════════════════

-- Fires on release, so Super used as a modifier (Super+Q, Super+drag, ...)
-- doesn't also open the launcher.
hl.bind("SUPER + Super_L", hl.dsp.global("shell:launcher"),
    { release = true, description = "App launcher" })
hl.bind("SUPER + T", hl.dsp.global("shell:settings"), { description = "Shell settings" })
hl.bind("SUPER + O", hl.dsp.global("shell:quick"), { description = "Quick settings" })
hl.bind("SUPER + H", hl.dsp.global("shell:cheat"), { description = "Keybind cheatsheet" })
hl.bind("SUPER + V", hl.dsp.global("shell:clip"), { description = "Clipboard history" })
hl.bind("SUPER + CTRL + P", hl.dsp.global("shell:ovpn"), { description = "VPN panel" })

-- Theme control through the glyph command (qs ipc under the hood).
local glyph = os.getenv("HOME") .. "/.local/bin/glyph"
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd(glyph .. " theme randomWall"), { description = "Random wallpaper" })
hl.bind("SUPER + ALT + D", hl.dsp.exec_cmd(glyph .. " theme light toggle"), { description = "Toggle dark / light" })
hl.bind("SUPER + ALT + N", hl.dsp.exec_cmd(glyph .. " shell run variant"), { description = "Next color variant" })
hl.bind("SUPER + K", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pick color (copies hex)" })
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell/rice/rice restart"), { release = true, description = "Restart the shell" })

-- ═══════════════════════════════════════════════════════════════════
-- 3. WINDOW MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + W", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ x = 900, y = 650 }))
    hl.dispatch(hl.dsp.window.center())
end, { description = "Toggle floating (centered)" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen(), { description = "Toggle fullscreen" })

-- Focus movement
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }), { description = "Focus left" })
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }), { description = "Focus right" })
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }), { description = "Focus up" })
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }), { description = "Focus down" })
hl.bind("ALT + Tab", hl.dsp.focus({ window = "next" }), { description = "Cycle focus" })
hl.bind("SUPER + U", hl.dsp.focus({ window = "urgent" }), { description = "Focus urgent window" })

-- Resize active window
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({ x = 30, y = 0 }), { repeating = true, description = "Grow right" })
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.resize({ x = -30, y = 0 }), { repeating = true, description = "Shrink left" })
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -30 }), { repeating = true, description = "Shrink up" })
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 30 }), { repeating = true, description = "Grow down" })

-- Move active window (float-aware)
hl.bind("SUPER + SHIFT + CTRL + Left", move_active(-30, 0, "left"), { description = "Move window left" })
hl.bind("SUPER + SHIFT + CTRL + Right", move_active(30, 0, "right"), { description = "Move window right" })
hl.bind("SUPER + SHIFT + CTRL + Up", move_active(0, -30, "up"), { description = "Move window up" })
hl.bind("SUPER + SHIFT + CTRL + Down", move_active(0, 30, "down"), { description = "Move window down" })

-- Mouse / key-triggered move & resize
-- Keep the grab point under the cursor when a tiled window is dragged
-- out (default re-centers the window on the cursor).
hl.config({ binds = { drag_center_window = false } })
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind("SUPER + Z", hl.dsp.window.drag(), { description = "Drag window (key)" })
hl.bind("SUPER + X", hl.dsp.window.resize(), { mouse = true, description = "Resize window (key)" })

-- Layout (dwindle)
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Toggle pseudo-tiling" })
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })
hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin(), { description = "Pin window to all workspaces" })
hl.bind("SUPER + SHIFT + C", hl.dsp.window.center(), { description = "Center floating window" })

-- Groups (tabbed windows). On SUPER so plain ALT+Left/Right stays free for
-- word-jump in shells/editors and back/forward in browsers.
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Toggle group (tabs)" })
hl.bind("SUPER + SHIFT + G", hl.dsp.group.lock({ all = true }), { description = "Lock groups" })
hl.bind("SUPER + ALT + Left", hl.dsp.group.prev(), { description = "Previous tab" })
hl.bind("SUPER + ALT + Right", hl.dsp.group.next(), { description = "Next tab" })

-- ═══════════════════════════════════════════════════════════════════
-- 4. SCREEN CAPTURE
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m window"),
    { description = "Screenshot window" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m output"),
    { description = "Screenshot screen" })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m region"),
    { description = "Screenshot region (save)" })
hl.bind("SUPER + SHIFT + S", hl.dsp.global("shell:shot"), { description = "Screenshot region" })
hl.bind("SUPER + A", hl.dsp.global("shell:shot"), { description = "Screenshot and annotate" })

-- Screen recording (gpu-screen-recorder → ~/Videos). Press again to stop.
local function record(region)
    return function()
        local mon = hl.get_active_monitor()
        local w = region and '-w region -region "$(slurp -f %wx%h+%x+%y)"' or "-w " .. (mon and mon.name or "region")
        hl.exec_cmd("pkill -INT -f '^gpu-screen-recorder' || gpu-screen-recorder " .. w ..
            ' -o "$(xdg-user-dir VIDEOS)/rec-$(date +%F_%H-%M-%S).mp4"')
    end
end
hl.bind("SUPER + R", record(false), { description = "Record screen (start/stop)" })
hl.bind("SUPER + SHIFT + R", record(true), { description = "Record region (start/stop)" })

-- ═══════════════════════════════════════════════════════════════════
-- 5. WORKSPACES
-- ═══════════════════════════════════════════════════════════════════

-- Switch to workspace 1–10 & Move window to workspace 1–10
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        { description = "Move window to workspace " .. i })
    hl.bind("SUPER + CTRL + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }),
        { description = "Send window to workspace " .. i })
end

-- Scratchpad: a dimmed overlay workspace for a terminal, notes, docs, etc.
-- Super+S also spawns a dropdown terminal there the first time (see the
-- scratchterm rule in windowrules.lua); after that it just toggles.
hl.bind("SUPER + S", function()
    if #hl.get_windows({ class = "scratchterm" }) == 0 then
        hl.exec_cmd("wezterm start --class scratchterm")
    else
        hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))
    end
end, { description = "Dropdown terminal / scratchpad" })
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:scratch" }), { description = "Send window to scratchpad" })

-- Workspace navigation
hl.bind("SUPER + grave", hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace" })
hl.bind("SUPER + SHIFT + grave", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace" })
hl.bind("SUPER + CTRL + Down", hl.dsp.focus({ workspace = "empty" }), { description = "Nearest empty workspace" })
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Scroll to next workspace" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Scroll to previous workspace" })
hl.bind("SUPER + CTRL + ALT + Right", hl.dsp.window.move({ workspace = "r+1" }), { description = "Move window to next workspace" })
hl.bind("SUPER + CTRL + ALT + Left", hl.dsp.window.move({ workspace = "r-1" }), { description = "Move window to previous workspace" })

-- ═══════════════════════════════════════════════════════════════════
-- 6. HARDWARE CONTROLS
-- ═══════════════════════════════════════════════════════════════════

-- Media keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Play / pause" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { description = "Previous track" })

-- Speaker volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true, description = "Mute speakers" })

-- Microphone
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true, description = "Mute microphone" })

-- Brightness (laptop)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"),
    { locked = true, repeating = true, description = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),
    { locked = true, repeating = true, description = "Brightness down" })

-- Touchpad
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("sudo -n /usr/local/bin/touchpad-reset"), { description = "Reset stuck touchpad" })

-- ═══════════════════════════════════════════════════════════════════
-- 7. SESSION
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + SHIFT + CTRL + Q", hl.dsp.exit(), { description = "Exit Hyprland (emergency)" })

-- ═══════════════════════════════════════════════════════════════════
-- 7b. EXTRAS
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize (keep bar and gaps)" })
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd("hyprctl kill"), { description = "Click a window to kill it" })
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "Sleep" })
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("pavucontrol"), { description = "Audio settings" })

-- ═══════════════════════════════════════════════════════════════════
-- 8. HYMISSION (Mission Control Overview)
-- ═══════════════════════════════════════════════════════════════════
-- https://github.com/gfhdhytghd/hymission

if hl.plugin and hl.plugin.hymission then
    hl.bind("SUPER + TAB", hl.plugin.hymission.toggle, { description = "Overview" })
    hl.bind("SUPER + SHIFT + TAB", function()
        hl.plugin.hymission.toggle("reverse")
    end, { description = "Overview (reverse)" })
    hl.bind("SUPER + CTRL + TAB", hl.plugin.hymission.close, { description = "Close overview" })
    -- open() ignores switch mode, so this overview stays up after Super is
    -- released; leave it with a click, Return or Escape.
    hl.bind("SUPER + Escape", function() hl.plugin.hymission.open() end, { description = "Overview (stay open)" })
    hl.bind("SUPER + CTRL + A", function()
        hl.plugin.hymission.toggle("forceall")
    end, { description = "Overview: all workspaces" })
    hl.bind("SUPER + CTRL + C", function()
        hl.plugin.hymission.toggle("onlycurrentworkspace")
    end, { description = "Overview: current workspace" })
    hl.bind("SUPER + M", hl.plugin.hymission.debug_current_layout, { description = "Overview: debug layout" })

    -- Fullscreen that stays inside its workspace tile.
    hl.unbind("SUPER + F")
    hl.bind("SUPER + F", function()
        hl.plugin.hymission.fullscreen({ mode = "fullscreen", action = "toggle" })
    end, { description = "Toggle fullscreen" })

    -- Stage: sidebar of live workspace cards.
    hl.bind("SUPER + comma", hl.plugin.hymission.stage_toggle, { description = "Stage sidebar" })

    -- Workspace tiles: up to three workspaces side by side.
    hl.bind("SUPER + backslash", function() hl.plugin.hymission.tile_add() end,
        { description = "Split: add workspace tile" })
    hl.bind("SUPER + SHIFT + backslash", function() hl.plugin.hymission.tile_remove() end,
        { description = "Split: remove tile" })
    hl.bind("SUPER + bracketleft", function() hl.plugin.hymission.tile_focus("left") end,
        { description = "Split: focus left tile" })
    hl.bind("SUPER + bracketright", function() hl.plugin.hymission.tile_focus("right") end,
        { description = "Split: focus right tile" })
    hl.bind("SUPER + SHIFT + bracketleft", function() hl.plugin.hymission.tile_move_window("left") end,
        { description = "Split: move window to left tile" })
    hl.bind("SUPER + SHIFT + bracketright", function() hl.plugin.hymission.tile_move_window("right") end,
        { description = "Split: move window to right tile" })
    hl.bind("SUPER + CTRL + bracketleft", function() hl.plugin.hymission.tile_resize({ delta = "-80px" }) end,
        { repeating = true, description = "Split: shrink tile" })
    hl.bind("SUPER + CTRL + bracketright", function() hl.plugin.hymission.tile_resize({ delta = "+80px" }) end,
        { repeating = true, description = "Split: grow tile" })

    -- Gestures. 4-finger vertical: one side opens all workspaces, the other
    -- the current one. 3-finger horizontal: workspace swipe that also works
    -- inside the overview (replaces the native one in inputs.lua).
    hl.plugin.hymission.gesture({
        fingers   = 4,
        direction = "vertical",
        action    = "toggle",
        recommand = true,
    })

    hl.plugin.hymission.gesture({
        fingers   = 3,
        direction = "horizontal",
        action    = "workspace",
    })

    hl.plugin.hymission.gesture({
        fingers   = 4,
        direction = "horizontal",
        mods      = "SUPER",
        action    = "stage_toggle",
    })
end
