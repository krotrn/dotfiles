-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                     ENVIRONMENT & STARTUP                      ║
-- ╚══════════════════════════════════════════════════════════════════╝
-- Environment variables and exec-once services
-- See: https://wiki.hypr.land/Configuring/Basics/Autostart/
-- See: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- ── Desktop Session ──────────────────────────────────────────────
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- ── Qt Theming ───────────────────────────────────────────────────
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- ── Electron / Chromium ──────────────────────────────────────────
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- ── Nvidia (uncomment if using Nvidia GPU) ───────────────────────
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- ── Autostart (exec-once) ────────────────────────────────────────
hl.on("hyprland.start", function()
    -- Noctalia shell (must start first per Noctalia v5 docs)
    hl.exec_cmd("noctalia")

    -- Polkit authentication agent (required)
    hl.exec_cmd(
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/libexec/polkit-gnome-authentication-agent-1")

    -- GNOME Keyring (optional - browser passwords)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

    -- Idle daemon
    hl.exec_cmd("hypridle &")

    -- Clipboard history
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Hyprland plugin manager & config reload
    hl.exec_cmd("hyprpm reload -n && hyprctl reload")
end)
