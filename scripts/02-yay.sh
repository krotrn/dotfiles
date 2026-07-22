#!/usr/bin/env bash
set -e

if command -v yay >/dev/null; then
    echo "yay already installed."
    exit 0
fi

echo "Installing yay..."

sudo pacman -S --needed git base-devel --noconfirm

tmp=$(mktemp -d)

git clone https://aur.archlinux.org/yay.git "$tmp/yay"

cd "$tmp/yay"

makepkg -si --noconfirm

rm -rf "$tmp"
