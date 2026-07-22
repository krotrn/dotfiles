#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"

echo "Copying configs..."

mkdir -p ~/.config

rsync -a --delete \
    "$ROOT/.config/" \
    ~/.config/

cp -f "$ROOT/.bashrc" ~/.bashrc 2>/dev/null || true
cp -f "$ROOT/.gitconfig" ~/.gitconfig 2>/dev/null || true
