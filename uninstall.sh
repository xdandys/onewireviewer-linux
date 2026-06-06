#!/usr/bin/env bash
#
# uninstall.sh - Remove a system-wide install.  Run as root: sudo ./uninstall.sh
#
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run with sudo:  sudo ./uninstall.sh" >&2; exit 1; }

rm -rf  /opt/onewireviewer
rm -f   /usr/local/bin/onewireviewer
rm -f   /etc/udev/rules.d/60-ds9490.rules
rm -f   /etc/modprobe.d/onewire-ds9490.conf
rm -f   /usr/share/applications/onewireviewer.desktop
udevadm control --reload-rules 2>/dev/null || true

echo "Uninstalled. (Per-user settings in ~/.config/onewireviewer were left intact.)"
echo "The 'blacklist ds2490' is removed; reboot to let the kernel module load again if you need it."
