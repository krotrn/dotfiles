-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                        KEYBINDS                                ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- All keyboard and mouse bindings
-- See: https://wiki.hypr.land/Configuring/Basics/Binds/

local scrPath = os.getenv("HOME") .. "/.config/hypr/Scripts"

-- ── Helper: shell command for checking floating state ────────────
local moveactivewindow = 'grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive'

-- ═══════════════════════════════════════════════════════════════════
-- 1. APPLICATIONS
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))                                                     -- Terminal
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))                                                         -- File Manager
hl.bind("SUPER + C", hl.dsp.exec_cmd("code"))                                                           -- VS Code
hl.bind("SUPER + B", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/Scripts/browser-launcher.sh")) -- Browser
hl.bind("SUPER + ALT + A", hl.dsp.exec_cmd("agy-ide"))                                                  -- Antigravity IDE

-- ═══════════════════════════════════════════════════════════════════
-- 2. NOCTALIA (v5 IPC)
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))                            -- Launcher
hl.bind("SUPER + L", hl.dsp.exec_cmd("noctalia msg session lock"))                                           -- Lockscreen
hl.bind("SUPER + T", hl.dsp.exec_cmd("noctalia msg settings-toggle"))                                        -- Settings
hl.bind("SUPER + O", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))                            -- Control Center
hl.bind("SUPER + H", hl.dsp.exec_cmd("noctalia msg plugin official/keybind-cheatsheet:main default toggle")) -- Keyhints
hl.bind("SUPER + K", hl.dsp.exec_cmd("noctalia msg plugin official/hyprland-keybinds:main default toggle"))  -- Keybind Editor

-- ═══════════════════════════════════════════════════════════════════
-- 3. WINDOW MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Q", hl.dsp.window.close())                           -- Close Window
hl.bind("SUPER + W", hl.dsp.window.float({ action = "toggle" }))      -- Toggle Floating
hl.bind("SUPER + F", hl.dsp.window.fullscreen())                      -- Toggle Fullscreen
hl.bind("SUPER + grave", hl.dsp.focus({ workspace = "m+1" }))         -- Workspace Up
hl.bind("SUPER + SHIFT + grave", hl.dsp.focus({ workspace = "m-1" })) -- Workspace Down

-- Focus movement
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }))  -- Focus Left
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" })) -- Focus Right
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }))    -- Focus Up
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }))  -- Focus Down
hl.bind("ALT + Tab", hl.dsp.focus({ window = "next" }))     -- Cycle Focus

-- Resize active window
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.resize({ x = 30, y = 0 }), { repeating = true }) -- Resize Right
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.resize({ x = -30, y = 0 }), { repeating = true }) -- Resize Left
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -30 }), { repeating = true })   -- Resize Up
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 30 }), { repeating = true })  -- Resize Down

-- Move active window (float-aware)
hl.bind("SUPER + SHIFT + CTRL + Left", hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l")) -- Move Left
hl.bind("SUPER + SHIFT + CTRL + Right", hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r")) -- Move Right
hl.bind("SUPER + SHIFT + CTRL + Up", hl.dsp.exec_cmd(moveactivewindow .. " 0 -30 || hyprctl dispatch movewindow u"))   -- Move Up
hl.bind("SUPER + SHIFT + CTRL + Down", hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"))  -- Move Down

-- Mouse binds
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })   -- Move Window (Mouse)
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- Resize Window (Mouse)

-- Key-triggered move/resize
hl.bind("SUPER + Z", hl.dsp.window.drag())                     -- Move Window (Key)
hl.bind("SUPER + X", hl.dsp.window.resize(), { mouse = true }) -- Resize Window (Key)

-- ═══════════════════════════════════════════════════════════════════
-- 4. SCREEN CAPTURE
-- ═══════════════════════════════════════════════════════════════════

hl.bind("SUPER + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m window"))         -- Screenshot Window
hl.bind("ALT + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m output"))           -- Screenshot Screen
hl.bind("SUPER + SHIFT + Print", hl.dsp.exec_cmd("HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m region")) -- Screenshot Region
hl.bind("SUPER + A",
    hl.dsp.exec_cmd(
        'grim -g "$(slurp)" - | satty --filename - --output-filename ~/Pictures/Screenshots/Screenshot-$(date \'+%Y%m%d-%H:%M:%S\').png')) -- Screenshot w/ Editor

-- ═══════════════════════════════════════════════════════════════════
-- 5. WORKSPACES
-- ═══════════════════════════════════════════════════════════════════

-- Switch to workspace 1–10 & Move window to workspace 1–10
for i = 1, 10 do
    local key = i % 10                                                        -- 10 maps to key 0
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }))               -- Workspace N
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i })) -- Move to Workspace N
end

-- Workspace navigation
hl.bind("SUPER + CTRL + Down", hl.dsp.focus({ workspace = "empty" }))            -- Nearest Empty Workspace
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))               -- Scroll Workspace Forward
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))                 -- Scroll Workspace Backward
hl.bind("SUPER + CTRL + ALT + Right", hl.dsp.window.move({ workspace = "r+1" })) -- Move to Next Relative
hl.bind("SUPER + CTRL + ALT + Left", hl.dsp.window.move({ workspace = "r-1" }))  -- Move to Previous Relative

-- ═══════════════════════════════════════════════════════════════════
-- 6. HARDWARE CONTROLS
-- ═══════════════════════════════════════════════════════════════════

-- Media keys
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Speaker volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })

-- Microphone
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })

-- ═══════════════════════════════════════════════════════════════════
-- 7. HYMISSION (Mission Control Overview)
-- ═══════════════════════════════════════════════════════════════════
-- https://github.com/gfhdhytghd/hymission

hl.bind("SUPER + Tab", hl.plugin.hymission.toggle) -- Toggle Overview
hl.bind("SUPER + SHIFT + Tab", function()          -- Toggle Reverse
    hl.plugin.hymission.toggle("reverse")
end)
hl.bind("SUPER + CTRL + Tab", hl.plugin.hymission.close) -- Close Overview
hl.bind("SUPER + CTRL + A", function()                   -- Overview (forceall)
    hl.plugin.hymission.toggle("forceall")
end)
hl.bind("SUPER + CTRL + C", function() -- Overview (current workspace)
    hl.plugin.hymission.toggle("onlycurrentworkspace")
end)
hl.bind("SUPER + M", hl.plugin.hymission.debug_current_layout) -- Debug Layout

-- Hymission gestures
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
