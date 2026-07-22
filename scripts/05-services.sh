#!/usr/bin/env bash
set -e

echo "Enabling services..."

systemctl --user enable --now pipewire.service || true
systemctl --user enable --now wireplumber.service || true
systemctl --user enable --now hypridle.service || true
