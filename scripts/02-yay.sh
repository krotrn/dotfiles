#!/usr/bin/env bash
set -e

if command -v yay >/dev/null 2>&1; then
    echo "yay already installed, skipping."
    exit 0
fi

echo "Installing yay..."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git clone https://aur.archlinux.org/yay.git "$tmp/yay"
(cd "$tmp/yay" && makepkg -si --noconfirm)

echo "yay installed."
