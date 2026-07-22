#!/usr/bin/env bash
set -e

if ! command -v hyprpm >/dev/null; then
    exit 0
fi

echo "Updating Hyprland plugins..."

hyprpm update

hyprpm reload
