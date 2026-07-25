#!/usr/bin/env bash
set -e

echo "Setting up Chaotic-AUR..."

# Check if already configured
if pacman -Sl chaotic-aur &>/dev/null; then
    echo "Chaotic-AUR already configured, skipping."
    exit 0
fi

# Import key and keyring
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

# Install chaotic-keyring and mirrorlist
sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Add repo to pacman.conf if not present
if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' \
        | sudo tee -a /etc/pacman.conf > /dev/null
fi

# Refresh databases
sudo pacman -Sy

echo "Chaotic-AUR configured."
