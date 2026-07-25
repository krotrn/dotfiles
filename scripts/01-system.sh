#!/usr/bin/env bash
set -e

echo "Updating system..."

sudo pacman -Syu --noconfirm

# Ensure git and base-devel are available for subsequent steps
sudo pacman -S --needed --noconfirm git base-devel
