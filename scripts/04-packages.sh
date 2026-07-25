#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"

# Helper: read package list, strip comments & blanks
read_pkgs() {
    grep -vE '^\s*(#|$)' "$1" | tr '\n' ' '
}

# ── Official repo packages ──
echo "Installing official packages..."
# shellcheck disable=SC2046
sudo pacman -S --needed --noconfirm $(read_pkgs "$ROOT/packages.txt")

# ── AUR packages ──
echo "Installing AUR packages..."
# shellcheck disable=SC2046
yay -S --needed --noconfirm $(read_pkgs "$ROOT/aur-packages.txt")

# ── Hardware-specific packages ──
# NVIDIA
if lspci | grep -qi 'nvidia'; then
    echo "NVIDIA GPU detected — installing drivers..."
    # shellcheck disable=SC2046
    yay -S --needed --noconfirm $(read_pkgs "$ROOT/hardware/nvidia.txt")
else
    echo "No NVIDIA GPU detected, skipping NVIDIA packages."
fi

# ASUS
if [ -d /sys/module/asus_wmi ] || [ -d /sys/module/asus_nb_wmi ] \
   || dmesg 2>/dev/null | grep -qi 'asus'; then
    echo "ASUS hardware detected — installing ASUS tools..."
    # shellcheck disable=SC2046
    yay -S --needed --noconfirm $(read_pkgs "$ROOT/hardware/asus.txt")
else
    echo "No ASUS hardware detected, skipping ASUS packages."
fi

echo "All packages installed."
