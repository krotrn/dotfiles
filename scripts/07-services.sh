#!/usr/bin/env bash
set -e

echo "Enabling services..."

# ── System services ──
sudo systemctl enable --now NetworkManager.service    || true
sudo systemctl enable --now bluetooth.service         || true
sudo systemctl enable --now docker.service            || true
sudo systemctl enable --now ufw.service               || true
# Display manager: SDDM with the glyph login theme (installed by 06c-system.sh); GDM stays installed as a fallback.
# -f replaces the display-manager link; it takes effect at the next boot (no --now: it would end this session).
if command -v sddm >/dev/null 2>&1; then
    sudo systemctl enable -f sddm.service                 || true
else
    sudo systemctl enable --now gdm.service               || true
fi
sudo systemctl enable --now power-profiles-daemon.service || true

# ── User services ──
systemctl --user enable --now pipewire.service        || true
systemctl --user enable --now wireplumber.service      || true
systemctl --user enable --now hypridle.service         || true

# ── Docker group ──
if ! groups | grep -q docker; then
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"
    echo "  ↳ You'll need to log out/in for docker group to take effect."
fi

# ── UFW basic rules ──
if command -v ufw >/dev/null 2>&1; then
    echo "Configuring firewall..."
    sudo ufw default deny incoming  2>/dev/null || true
    sudo ufw default allow outgoing 2>/dev/null || true
    sudo ufw --force enable         2>/dev/null || true
fi

echo "Services enabled."
