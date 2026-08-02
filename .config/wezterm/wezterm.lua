local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font
config.font = wezterm.font_with_fallback({"JetBrainsMono Nerd Font", "Noto Color Emoji",})
config.hide_mouse_cursor_when_typing = true
config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.font_size = 12.5
config.line_height = 1.1
config.default_prog = { "/usr/bin/zsh", "-l" }
-- Color Scheme
config.colors = {
  foreground = "#E6E6E6",
  background = "#000000",
  cursor_bg = "#FFFFFF",
  cursor_fg = "#000000",
  cursor_border = "#FFFFFF",
  selection_bg = "#2D2D2D",
  selection_fg = "#FFFFFF",

  ansi = {
    "#000000",
    "#FF5F56",
    "#27C93F",
    "#F8D866",
    "#4DA3FF",
    "#C678DD",
    "#56B6C2",
    "#D9D9D9",
  },

  brights = {
    "#666666",
    "#FF6E67",
    "#5AF78E",
    "#F4F99D",
    "#57C7FF",
    "#FF6AC1",
    "#9AEDFE",
    "#FFFFFF",
  },
}

-- Window
config.window_decorations = "NONE"
config.enable_tab_bar = false
config.window_close_confirmation = "NeverPrompt"
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}

config.initial_cols = 120
config.initial_rows = 32

-- Opacity & Blur (Hyprland)
config.window_background_opacity = 0.85
config.text_background_opacity = 1.0

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600

-- Performance
config.max_fps = 144
config.animation_fps = 144
config.front_end = "WebGpu"

-- Scrollback
config.scrollback_lines = 100000

-- Disable audible bell
config.audible_bell = "Disabled"

-- Keybindings
config.keys = {
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.ToggleFullScreen,
	},
	{
		key = "c",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CopyTo("Clipboard"),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "w",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CloseCurrentTab({ confirm = false }),
	},
}

config.color_scheme = "Noctalia"
return config
