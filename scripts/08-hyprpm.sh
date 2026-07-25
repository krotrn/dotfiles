#!/usr/bin/env bash
set -e

if ! command -v hyprpm >/dev/null 2>&1; then
    echo "hyprpm not found, skipping Hyprland plugins."
    exit 0
fi

echo "Setting up Hyprland plugins..."

hyprpm update || true

# ── Add plugins ──
hyprpm add https://github.com/horriblename/hyprgrass  2>/dev/null || true
hyprpm add https://github.com/gfhdhytghd/hymission    2>/dev/null || true

# ── Enable plugins ──
hyprpm enable hyprgrass  2>/dev/null || true
hyprpm enable hymission  2>/dev/null || true

hyprpm reload || true

echo "Hyprland plugins configured."
