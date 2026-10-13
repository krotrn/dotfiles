-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                     ENVIRONMENT & STARTUP                      ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Environment variables and exec-once services
-- See: https://wiki.hypr.land/Configuring/Basics/Autostart/
-- See: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
-- ── Desktop Session ──────────────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("TERMINAL", "wezterm")
-- ── Qt Theming ───────────────────────────────────────────────────
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- ── Electron / Chromium ──────────────────────────────────────────
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- ── Toolkit Backends ─────────────────────────────────────────────
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- ── Nvidia (uncomment if using Nvidia GPU) ───────────────────────
hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm") -- Disabled: explicit sync in Hyprland v0.52+ handles buffer allocation
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("NVD_BACKEND", "direct") -- Disabled: causes buffer sync stalls with Wayland layer shells
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")

-- ── Autostart (exec-once) ────────────────────────────────────────
hl.on("hyprland.start", function()
	-- D-Bus environment (must be first for portals/keyring)
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Noctalia shell (must start first per Noctalia v5 docs)
	hl.exec_cmd("noctalia")

	-- Polkit authentication agent (required)
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

	-- GNOME Keyring (optional - browser passwords)
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets --foreground")

	-- Idle daemon
	hl.exec_cmd("hypridle")

	-- Clipboard history
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Load Hyprland plugins (hyprpm), then re-parse config so guarded
	-- plugin settings (hymission, hyprgrass) are applied without errors
	hl.exec_cmd("hyprpm reload -n && hyprctl reload")
end)
