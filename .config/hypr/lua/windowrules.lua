-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                      WINDOW RULES                              ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Window-specific behavior: floating, idle inhibit, PiP
-- See: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- ═══════════════════════════════════════════════════════════════════
-- FLOATING RULES
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({ match = { class = "^org\\.pulseaudio\\.pavucontrol$" }, float = true })
hl.window_rule({ match = { class = "^de\\.haeckerfelix\\.Shortwave$" }, float = true })
hl.window_rule({ match = { class = "^com\\.github\\.iwalton3\\.jellyfin-media-player$" }, float = true })

-- Brave untitled windows: float, center, and size
hl.window_rule({
	match = { class = "^brave-browser$", initial_title = "^Untitled - Brave$" },
	float = true,
	center = true,
	size = { 600, 800 },
})

-- ═══════════════════════════════════════════════════════════════════
-- IDLE INHIBIT RULES
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({
	match = { class = "^(.*celluloid.*|.*mpv.*|.*vlc.*)$" },
	idle_inhibit = "fullscreen",
})
hl.window_rule({
	match = { class = "^.*[Ss]potify.*$" },
	idle_inhibit = "fullscreen",
})
hl.window_rule({
	match = { class = "^(.*LibreWolf.*|.*floorp.*|.*brave-browser.*|.*firefox.*|.*chromium.*|.*zen.*|.*vivaldi.*)$" },
	idle_inhibit = "fullscreen",
})

-- ═══════════════════════════════════════════════════════════════════
-- PICTURE-IN-PICTURE
-- ═══════════════════════════════════════════════════════════════════

hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture).*$" }, tag = "+picture-in-picture" })
hl.window_rule({
	match = { tag = "picture-in-picture" },
	float = true,
	keep_aspect_ratio = true,
	pin = true,
	move = { "73%", "72%" },
	size = "25% 25%",
})

-- ═══════════════════════════════════════════════════════════════════
-- FLOATING UTILITIES
-- ═══════════════════════════════════════════════════════════════════

local float_classes = {
	"^Signal$",
	"^com\\.github\\.rafostar\\.Clapper$",
	"^app\\.drey\\.Warp$",
	"^net\\.davidotek\\.pupgui2$",
	"^yad$",
	"^eog$",
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
	match = { class = "^.*jetbrains.*$", title = "^win[0-9]+$" },
	no_initial_focus = true,
})

-- YAD cheat sheet
hl.window_rule({
	match = { class = "^yad$" },
	center = true,
	size = { 1200, 900 },
})

-- ═══════════════════════════════════════════════════════════════════
-- GAMING — Immediate render, no blur
-- ═══════════════════════════════════════════════════════════════════
hl.window_rule({
	match = { class = "^[Ss]team_app_.*$" },
	immediate = true,
	no_blur = true,
	xray = false,
})

-- ═══════════════════════════════════════════════════════════════════
-- FILE DIALOGS — float and center
-- ═══════════════════════════════════════════════════════════════════
-- Match whole dialog titles only: a bare "^Open.*" also caught browser and
-- editor windows whose title happened to start with "Open"/"Select"/etc.
hl.window_rule({
	match = { title = "^(Open|Open Files?|Open Folder|Save|Save As|Save File|Select (a )?Files?|Select Folder|Choose Files?|File Upload)$" },
	float = true,
	center = true,
	size = { 900, 600 },
})
hl.window_rule({
	match = { class = "^(xdg-desktop-portal-gtk|org\\.freedesktop\\.impl\\.portal\\.desktop\\..*)$" },
	float = true,
	center = true,
	size = { 900, 600 },
})
