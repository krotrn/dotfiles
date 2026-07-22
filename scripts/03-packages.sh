#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"

echo "Installing official packages..."

sudo pacman -S --needed --noconfirm \
    $(grep -v '^#' "$ROOT/packages.txt")

echo "Installing AUR packages..."

yay -S --needed --noconfirm \
    $(grep -v '^#' "$ROOT/aur-packages.txt")
