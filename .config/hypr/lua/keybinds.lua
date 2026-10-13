-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        KEYBINDS                                ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- All keyboard and mouse bindings
-- See: https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- Each bind's `description` is what the Super+H cheatsheet shows, and the
-- numbered section headings below become its categories.

local scrPath = os.getenv("HOME") .. "/.config/hypr/Scripts"

-- ── Helper: shell command for checking floating state ────────────
local moveactivewindow = 'grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive'

-- ═══════════════════════════════════════════════════════════════════
-- 1. APPLICATIONS
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("wezterm"), { description = "Terminal" })
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "File manager" })
hl.bind("SUPER + C", hl.dsp.exec_cmd("code"), { description = "VS Code" })
hl.bind("SUPER + B", hl.dsp.exec_cmd(scrPath .. "/browser-launcher.sh"), { description = "Browser" })
hl.bind("SUPER + ALT + A", hl.dsp.exec_cmd("agy-ide"), { description = "Antigravity IDE" })

-- ═══════════════════════════════════════════════════════════════════
-- 2. NOCTALIA (v5 IPC)
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { description = "App launcher" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("noctalia msg session lock"), { description = "Lock screen" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("noctalia msg settings-toggle"), { description = "Noctalia settings" })
hl.bind("SUPER + O", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"), { description = "Control center" })
hl.bind("SUPER + H", hl.dsp.exec_cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
    { description = "Keybind cheatsheet" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"), { description = "Clipboard history" })
hl.bind("SUPER + I", hl.dsp.exec_cmd("noctalia msg caffeine-toggle"), { description = "Caffeine (pause auto-lock)" })
hl.bind("SUPER + K", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Pick color (copies hex)" })

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
hl.bind("SUPER + SHIFT + CTRL + Left", hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l"),
    { description = "Move window left" })
hl.bind("SUPER + SHIFT + CTRL + Right", hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r"),
    { description = "Move window right" })
hl.bind("SUPER + SHIFT + CTRL + Up", hl.dsp.exec_cmd(moveactivewindow .. " 0 -30 || hyprctl dispatch movewindow u"),
    { description = "Move window up" })
hl.bind("SUPER + SHIFT + CTRL + Down", hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"),
    { description = "Move window down" })

-- Mouse / key-triggered move & resize
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })
hl.bind("SUPER + Z", hl.dsp.window.drag(), { description = "Drag window (key)" })
hl.bind("SUPER + X", hl.dsp.window.resize(), { mouse = true, description = "Resize window (key)" })

-- Layout (dwindle)
hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Toggle pseudo-tiling" })
hl.bind("SUPER + J", hl.dsp.exec_cmd("hyprctl dispatch togglesplit"), { description = "Toggle split direction" })
hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin(), { description = "Pin window to all workspaces" })
hl.bind("SUPER + SHIFT + C", hl.dsp.window.center(), { description = "Center floating window" })

-- Groups (tabbed windows). On SUPER so plain ALT+Left/Right stays free for
-- word-jump in shells/editors and back/forward in browsers.
hl.bind("SUPER + G", hl.dsp.group.toggle(), { description = "Toggle group (tabs)" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("hyprctl dispatch lockgroups toggle"), { description = "Lock groups" })
hl.bind("SUPER + ALT + Left", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive b"), { description = "Previous tab" })
hl.bind("SUPER + ALT + Right", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive f"), { description = "Next tab" })

-- ═══════════════════════════════════════════════════════════════════
-- 4. SCREEN CAPTURE
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m window"),
    { description = "Screenshot window" })
hl.bind("ALT + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m output"),
    { description = "Screenshot screen" })
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m region"),
    { description = "Screenshot region (save)" })
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("noctalia msg screenshot-region"), { description = "Screenshot region" })
hl.bind("SUPER + A", hl.dsp.exec_cmd("noctalia msg screenshot-annotate"), { description = "Screenshot and annotate" })

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

hl.bind("SUPER + SHIFT + CTRL + Q", hl.dsp.exec_cmd("hyprctl dispatch exit"), { description = "Exit Hyprland (emergency)" })

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
    hl.bind("SUPER + CTRL + A", function()
        hl.plugin.hymission.toggle("forceall")
    end, { description = "Overview: all workspaces" })
    hl.bind("SUPER + CTRL + C", function()
        hl.plugin.hymission.toggle("onlycurrentworkspace")
    end, { description = "Overview: current workspace" })
    hl.bind("SUPER + M", hl.plugin.hymission.debug_current_layout, { description = "Overview: debug layout" })

    -- Hymission Gestures
    hl.plugin.hymission.gesture({
        fingers   = 4,
        direction = "vertical",
        action    = "toggle",
        recommand = true,
    })

    hl.plugin.hymission.gesture({
        fingers   = 3,
        direction = "horizontal",
        action    = "scroll",
        mode      = "layout",
    })

    hl.plugin.hymission.gesture({
        fingers   = 3,
        direction = "horizontal",
        action    = "workspace",
    })
end
