#!/usr/bin/env bash
# System-level tuning: files that live in /etc and /usr/local (root-owned), so they are COPIED with sudo, not symlinked.
# Hardware-specific parts only run on matching hardware. Safe to re-run: a file is only replaced when it differs.
#   DRY_RUN=1 scripts/06c-system.sh     shows what would be done without touching anything
set -e

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
S="$ROOT/system"

run() { if [ "${DRY_RUN:-0}" = 1 ]; then echo "    [dry-run] $*"; else "$@"; fi; }

# put <mode> <source> <destination>: copies when the destination is missing or different. Returns 1 when nothing changed.
put() {
    local mode="$1" src="$2" dest="$3"
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo "  ✔ $dest (up to date)"
        return 1
    fi
    run sudo install -Dm"$mode" -o root -g root "$src" "$dest"
    echo "  ✔ $dest"
}

echo "Installing system tuning..."

# ── Kernel: let perf tools read events as a normal user ──
if put 644 "$S/etc/sysctl.d/99-perf.conf" /etc/sysctl.d/99-perf.conf; then
    run sudo sysctl --system >/dev/null
fi

# ── Intel Wi-Fi: no power saving (fewer drops); takes effect after a reboot ──
if [ -d /sys/module/iwlwifi ] || lsmod 2>/dev/null | grep -q '^iwlwifi'; then
    put 644 "$S/etc/modprobe.d/iwlwifi.conf" /etc/modprobe.d/iwlwifi.conf || true
else
    echo "  – no Intel Wi-Fi (iwlwifi) detected, skipping its options"
fi

# ── Groups the desktop uses ──
for g in input video i2c seat; do
    if getent group "$g" >/dev/null && ! id -nG "$USER" | tr ' ' '\n' | grep -qx "$g"; then
        echo "  ↳ adding $USER to group $g"
        run sudo usermod -aG "$g" "$USER"
    fi
done

# ── ASUS laptop: battery charge limit and the touchpad reset ──
if [ -d /sys/module/asus_wmi ] || [ -d /sys/module/asus_nb_wmi ]; then
    # the udev rule gives the group battery_ctl write access to the charge limit
    getent group battery_ctl >/dev/null || run sudo groupadd battery_ctl
    id -nG "$USER" | tr ' ' '\n' | grep -qx battery_ctl || run sudo usermod -aG battery_ctl "$USER"
    if put 644 "$S/etc/udev/rules.d/99-battery-threshold.rules" /etc/udev/rules.d/99-battery-threshold.rules; then
        run sudo udevadm control --reload
        run sudo udevadm trigger --subsystem-match=power_supply
    fi

    # touchpad-reset (Super+Shift+T). It must be a ROOT-OWNED copy: a script you can edit must never be run by sudo
    # without a password. The sudo rule allows exactly this one command.
    if [ -d /sys/bus/i2c/devices/i2c-ASUP1205:00 ]; then
        put 755 "$ROOT/bin/touchpad-reset" /usr/local/bin/touchpad-reset || true
        rule="$(mktemp)"
        echo "$USER ALL=(root) NOPASSWD: /usr/local/bin/touchpad-reset" > "$rule"
        if run sudo visudo -cf "$rule" >/dev/null; then
            put 440 "$rule" /etc/sudoers.d/touchpad-reset || true
        fi
        rm -f "$rule"
    else
        echo "  – ASUP1205 touchpad not found, skipping touchpad-reset"
    fi
else
    echo "  – not an ASUS laptop, skipping the battery limit and touchpad reset"
fi

echo "System tuning done."
