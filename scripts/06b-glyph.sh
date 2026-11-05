#!/usr/bin/env bash
# glyph shell (quickshell): links the shell, its settings and its fonts into place.
# The packages it needs are in ../packages.txt (installed by 04-packages.sh), the config files under
# ../.config/{glyph,demonshot} are linked by 06-configs.sh and again here, so this script also works alone:
#   scripts/06b-glyph.sh
set -e

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
G="$ROOT/glyph"

echo "Linking the glyph shell..."

# Creates a symlink; an existing real file or folder is kept as <name>.bak (never overwritten).
safe_link() {
    local src="$1" dest="$2"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "  ✔ $dest (already linked)"
        return
    fi
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        local bak="${dest}.bak"
        [ -e "$bak" ] && bak="${dest}.bak-$(date +%F_%H-%M-%S)"
        echo "  ↳ backing up $dest → $bak"
        mv "$dest" "$bak"
    fi
    [ -L "$dest" ] && rm "$dest"
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "  ✔ $dest"
}

mkdir -p "$HOME/.config/quickshell" "$HOME/.local/bin" "$HOME/.local/share/fonts" "$HOME/.local/state"

# the shell and its switcher (the rice command starts and restarts the shell)
safe_link "$G/quickshell/glyph" "$HOME/.config/quickshell/glyph"
safe_link "$G/quickshell/rice" "$HOME/.config/quickshell/rice"
safe_link "$G/quickshell/rice/rice" "$HOME/.local/bin/rice"
safe_link "$G/qtengine" "$HOME/.config/qtengine"

# fonts of the shell (Doto, Space Mono, Space Grotesk) are NOT installed on purpose: with them the shell's text
# rendered as garbled symbols. The files stay in glyph/fonts/ for a later try; without them the shell uses
# Noto Sans and JetBrainsMono Nerd Font. To try them: ln -s "$G/fonts" "$HOME/.local/share/fonts/glyph" && fc-cache -f
# (and remove that link again if the text looks wrong)

# settings the shell saves itself (home widgets, bar, colors, rules, hidden projects).
# Whole folders are linked, not single files: the shell saves by writing a new file and renaming it,
# which would silently replace a linked file.
safe_link "$G/state" "$HOME/.local/state/rice"
safe_link "$ROOT/.config/glyph" "$HOME/.config/glyph"
safe_link "$ROOT/.config/demonshot" "$HOME/.config/demonshot"

# the wallpaper picker looks here
mkdir -p "$HOME/Pictures/Wallpapers"

command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true

# dark mode for GTK and libadwaita apps (the shell's palette is black and white)
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark 2>/dev/null || true
fi

echo "glyph shell linked. Start it with: rice start   (or log in again: Hyprland starts it)"
