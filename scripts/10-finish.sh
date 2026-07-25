#!/usr/bin/env bash

# Reload Hyprland if running
hyprctl reload 2>/dev/null || true

echo
echo "Done. 🎉"
echo "Run 'dotfiles' to see available management commands."
