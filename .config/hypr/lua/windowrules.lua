-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                      WINDOW RULES                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Window-specific behavior: floating, opacity, idle inhibit, PiP
-- See: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- ═══════════════════════════════════════════════════════════════════
-- FLOATING RULES
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({ match = { class = "^org\\.pulseaudio\\.pavucontrol$" },    float = true })
hl.window_rule({ match = { class = "^de\\.haeckerfelix\\.Shortwave$" },     float = true })
hl.window_rule({ match = { class = "^com\\.github\\.iwalton3\\.jellyfin-media-player$" }, float = true })

-- Brave untitled windows: float, center, and size
hl.window_rule({
    match = { class = "^brave-browser$", initial_title = "^Untitled - Brave$" },
    float  = true,
    center = true,
    size   = {600, 800},
})

-- ═══════════════════════════════════════════════════════════════════
-- IDLE INHIBIT RULES
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({ match = { class = "^(.*celluloid.*|.*mpv.*|.*vlc.*)$" },                                                                 idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "^.*[Ss]potify.*$" },                                                                                   idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "^(.*LibreWolf.*|.*floorp.*|.*brave-browser.*|.*firefox.*|.*chromium.*|.*zen.*|.*vivaldi.*)$" },         idle_inhibit = "fullscreen" })

-- ═══════════════════════════════════════════════════════════════════
-- PICTURE-IN-PICTURE
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture).*$" }, tag = "+picture-in-picture" })
hl.window_rule({
    match            = { tag = "picture-in-picture" },
    float            = true,
    keep_aspect_ratio = true,
    pin              = true,
    move             = {"73%", "72%"},
    size             = "25% 25%",
})

-- ═══════════════════════════════════════════════════════════════════
-- OPACITY RULES
-- ═══════════════════════════════════════════════════════════════════

local opacity_classes = {
    -- Browsers
    "^firefox$", "^brave-browser$",
    -- Editors
    "^code-oss$", "^[Cc]ode$", "^code-url-handler$", "^code-insiders-url-handler$",
    -- Terminals
    "^kitty$", "^foot$",
    -- File managers & tools
    "^org\\.kde\\.dolphin$", "^org\\.kde\\.ark$",
    "^nwg-look$", "^qt5ct$", "^qt6ct$", "^extsource$", "^kvantummanager$",
    -- System
    "^org\\.pulseaudio\\.pavucontrol$", "^blueman-manager$",
    "^nm-applet$", "^nm-connection-editor$",
    -- Auth agents
    "^org\\.kde\\.polkit-kde-authentication-agent-1$",
    "^polkit-gnome-authentication-agent-1$",
    -- Portals
    "^org\\.freedesktop\\.impl\\.portal\\.desktop\\.gtk$",
    "^org\\.freedesktop\\.impl\\.portal\\.desktop\\.hyprland$",
    -- Gaming
    "^[Ss]team$", "^steamwebhelper$",
    -- Media
    "^[Ss]potify$",
    -- Apps
    "^com\\.github\\.rafostar\\.Clapper$", "^com\\.github\\.tchx84\\.Flatseal$",
    "^hu\\.kramo\\.Cartridges$", "^com\\.obsproject\\.Studio$",
    "^gnome-boxes$", "^vesktop$", "^discord$", "^WebCord$", "^ArmCord$",
    "^app\\.drey\\.Warp$", "^net\\.davidotek\\.pupgui2$", "^yad$",
    "^Signal$", "^io\\.github\\.alainm23\\.planify$",
    "^io\\.gitlab\\.theevilskeleton\\.Upscaler$",
    "^com\\.github\\.unrud\\.VideoDownloader$",
    "^io\\.gitlab\\.adhami3310\\.Impression$",
    "^io\\.missioncenter\\.MissionCenter$",
    "^io\\.github\\.flattool\\.Warehouse$",
}

for _, cls in ipairs(opacity_classes) do
    hl.window_rule({ match = { class = cls }, opacity = "1.00" })
end

-- Spotify by title
hl.window_rule({ match = { initial_title = "^Spotify Free$" },    opacity = "1.00" })
hl.window_rule({ match = { initial_title = "^Spotify Premium$" }, opacity = "1.00" })

-- ═══════════════════════════════════════════════════════════════════
-- FLOATING UTILITIES
-- ═══════════════════════════════════════════════════════════════════

local float_classes = {
    "^Signal$",
    "^com\\.github\\.rafostar\\.Clapper$",
    "^app\\.drey\\.Warp$",
    "^net\\.davidotek\\.pupgui2$",
    "^yad$", "^eog$",
    "^io\\.github\\.alainm23\\.planify$",
    "^io\\.gitlab\\.theevilskeleton\\.Upscaler$",
    "^com\\.github\\.unrud\\.VideoDownloader$",
    "^io\\.gitlab\\.adhami3310\\.Impression$",
    "^io\\.missioncenter\\.MissionCenter$",
}

for _, cls in ipairs(float_classes) do
    hl.window_rule({ match = { class = cls }, float = true })
end

-- ═══════════════════════════════════════════════════════════════════
-- MISC RULES
-- ═══════════════════════════════════════════════════════════════════

-- JetBrains popup fix
hl.window_rule({
    match            = { class = "^.*jetbrains.*$", title = "^win[0-9]+$" },
    no_initial_focus = true,
})

-- YAD cheat sheet
hl.window_rule({
    match  = { class = "^yad$" },
    center = true,
    size   = {1200, 900},
})

-- ═══════════════════════════════════════════════════════════════════
-- GAMING — Immediate render, no blur
-- ═══════════════════════════════════════════════════════════════════
hl.window_rule({
    match     = { class = "^[Ss]team_app_.*$" },
    immediate = true,
    no_blur   = true,
    xray      = false,
})

-- ═══════════════════════════════════════════════════════════════════
-- FILE DIALOGS — float and center
-- ═══════════════════════════════════════════════════════════════════
hl.window_rule({
    match  = { title = "^(Open|Save|Save As|Select|Choose|Pick).*$" },
    float  = true,
    center = true,
    size   = { 900, 600 },
})

-- ═══════════════════════════════════════════════════════════════════
-- WEZTERM — terminal opacity
-- ═══════════════════════════════════════════════════════════════════
hl.window_rule({
    match   = { class = "^org\\.wezfurlong\\.wezterm$" },
    opacity = "0.95 0.90",
})
