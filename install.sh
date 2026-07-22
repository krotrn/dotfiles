#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo
echo "======================================="
echo "      Karan's Arch Bootstrap"
echo "======================================="
echo

for script in "$ROOT"/scripts/*.sh; do
    bash "$script"
done

echo
echo "✔ Installation completed!"
echo
echo "Reboot recommended."
