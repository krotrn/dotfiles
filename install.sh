#!/usr/bin/env bash
set -euo pipefail

# ── Colours ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ROOT="$(cd "$(dirname "$0")" && pwd)"

banner() {
    echo
    echo -e "${CYAN}${BOLD}"
    echo "  ╔═══════════════════════════════════╗"
    echo "  ║     Karan's Arch Bootstrap        ║"
    echo "  ║     Dotfiles Installer             ║"
    echo "  ╚═══════════════════════════════════╝"
    echo -e "${NC}"
}

# ── Pre-flight checks ──
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}✗ Do not run this script as root. Run as your normal user.${NC}"
    exit 1
fi

if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}✗ This script is designed for Arch Linux.${NC}"
    exit 1
fi

banner

echo -e "${YELLOW}This will install packages, symlink configs, and set up your system.${NC}"
echo -e "${YELLOW}Existing config files will be backed up with a .bak extension.${NC}"
echo
read -rp "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo

# ── Run each setup script in order ──
for script in "$ROOT"/scripts/[0-9]*.sh; do
    [ -f "$script" ] || continue
    step=$(basename "$script")
    echo -e "${CYAN}${BOLD}── Running ${step} ──${NC}"
    bash "$script"
    echo -e "${GREEN}✔ ${step} done${NC}"
    echo
done

echo -e "${GREEN}${BOLD}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║     ✔ Installation Complete!      ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Run ${CYAN}dotfiles${NC} to manage your configs."
echo -e "  A ${YELLOW}reboot${NC} is recommended."
echo
