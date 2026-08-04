#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"

echo "Symlinking dotfiles..."

# ── Helper: safe symlink ──
# Creates a symlink, backing up any existing non-symlink target.
safe_link() {
    local src="$1"   # absolute path to source (in repo)
    local dest="$2"  # absolute path to destination (in $HOME)

    # If destination exists and is NOT a symlink, back it up
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "  ↳ backing up $(basename "$dest") → ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi

    # Remove existing symlink if it points somewhere else
    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"

    ln -s "$src" "$dest"
    echo "  ✔ $(basename "$dest")"
}

# ── Symlink .config directories ──
echo "Linking ~/.config directories..."
mkdir -p "$HOME/.config"

for item in "$ROOT/.config"/*/; do
    [ -d "$item" ] || continue
    dirname=$(basename "$item")
    if [ "$dirname" = "gtk-3.0" ]; then
        mkdir -p "$HOME/.config/gtk-3.0"
        for subitem in "$item"*; do
            [ -e "$subitem" ] || continue
            subname=$(basename "$subitem")
            if [ "$subname" = "bookmarks" ]; then
                sed "s|\$HOME|$HOME|g" "$subitem" > "$HOME/.config/gtk-3.0/bookmarks"
                echo "  ✔ gtk-3.0/bookmarks (templated)"
            else
                safe_link "$subitem" "$HOME/.config/gtk-3.0/$subname"
            fi
        done
    else
        safe_link "$item" "$HOME/.config/$dirname"
    fi
done

# ── Symlink .config files (starship.toml, mimeapps.list, etc.) ──
echo "Linking ~/.config files..."
for item in "$ROOT/.config"/*; do
    [ -f "$item" ] || continue
    filename=$(basename "$item")
    safe_link "$item" "$HOME/.config/$filename"
done

# ── Symlink home-level dotfiles ──
echo "Linking home dotfiles..."
for dotfile in .bashrc .zshrc .gitconfig; do
    [ -f "$ROOT/$dotfile" ] || continue
    safe_link "$ROOT/$dotfile" "$HOME/$dotfile"
done

# ── Install the dotfiles helper to PATH ──
echo "Installing dotfiles helper..."
mkdir -p "$HOME/.local/bin"
safe_link "$ROOT/bin/dotfiles" "$HOME/.local/bin/dotfiles"

# ── Symlink Noctalia state settings for live GUI auto-sync ──
if [ -d "$ROOT/.config/noctalia" ]; then
    echo "Linking Noctalia state settings..."
    mkdir -p "$HOME/.local/state/noctalia"
    touch "$ROOT/.config/noctalia/settings.toml"
    safe_link "$ROOT/.config/noctalia/settings.toml" "$HOME/.local/state/noctalia/settings.toml"
fi

echo "All configs symlinked."
