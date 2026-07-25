#!/usr/bin/env bash
set -e

echo "Setting default shell to zsh..."

ZSH_PATH="$(which zsh 2>/dev/null || echo /usr/bin/zsh)"

if [ "$(basename "$SHELL")" = "zsh" ]; then
    echo "zsh is already the default shell."
    exit 0
fi

if [ ! -x "$ZSH_PATH" ]; then
    echo "zsh not found, skipping."
    exit 0
fi

# Ensure zsh is in /etc/shells
if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
fi

chsh -s "$ZSH_PATH"

echo "Default shell set to zsh."
