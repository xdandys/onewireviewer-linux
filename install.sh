#!/usr/bin/env bash
#
# install.sh - Install OneWireViewer + the DS9490R USB driver system-wide.
# Run as root:  sudo ./install.sh   (after building as your normal user: ./build.sh)
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP=/opt/onewireviewer

[ "$(id -u)" = 0 ] || { echo "Run with sudo:  sudo ./install.sh" >&2; exit 1; }
[ -f "$ROOT/build/libonewireUSB.so" ] || { echo "Build first (as your normal user):  ./build.sh" >&2; exit 1; }

echo "==> Installing app to $APP"
install -d "$APP/classes/com/dalsemi/onewire/adapter"
install -m644 "$ROOT/lib/OneWireAPI.jar"      "$APP/"
install -m644 "$ROOT/build/OneWireViewer.jar" "$APP/"
install -m755 "$ROOT/build/libonewireUSB.so"  "$APP/"
install -m644 "$ROOT/build/classes/com/dalsemi/onewire/adapter/PDKAdapterUSB.class" \
              "$APP/classes/com/dalsemi/onewire/adapter/"
install -m644 "$ROOT/onewire.properties"      "$APP/"

echo "==> Installing launcher /usr/local/bin/onewireviewer"
cat >/usr/local/bin/onewireviewer <<'LAUNCH'
#!/usr/bin/env bash
APPDIR=/opt/onewireviewer
WORK="${XDG_CONFIG_HOME:-$HOME/.config}/onewireviewer"
mkdir -p "$WORK"
[ -f "$WORK/onewire.properties" ] || cp "$APPDIR/onewire.properties" "$WORK/"
cd "$WORK"
exec java --enable-native-access=ALL-UNNAMED \
  -Djava.library.path="$APPDIR" \
  -cp "$APPDIR/OneWireAPI.jar:$APPDIR/OneWireViewer.jar:$APPDIR/classes" \
  OneWireViewer "$@"
LAUNCH
chmod 755 /usr/local/bin/onewireviewer

echo "==> Installing udev rule (grants the local user access to the DS9490R)"
cat >/etc/udev/rules.d/60-ds9490.rules <<'UDEV'
# Maxim DS9490R 1-Wire USB adapter (DS2490 chip)
SUBSYSTEM=="usb", ATTR{idVendor}=="04fa", ATTR{idProduct}=="2490", MODE="0664", TAG+="uaccess"
UDEV

echo "==> Blacklisting kernel ds2490 so libusb can claim the adapter"
cat >/etc/modprobe.d/onewire-ds9490.conf <<'BL'
# Free the DS9490R for libusb / OneWireViewer (the kernel w1 stack would otherwise grab it)
blacklist ds2490
BL

echo "==> Installing desktop entry"
cat >/usr/share/applications/onewireviewer.desktop <<'DESK'
[Desktop Entry]
Type=Application
Name=OneWireViewer
Comment=Explore 1-Wire / iButton devices (DS9490R)
Exec=onewireviewer
Terminal=false
Categories=Utility;Electronics;
DESK

udevadm control --reload-rules 2>/dev/null || true

cat <<'DONE'

Done. Launch with:  onewireviewer   (or from your application menu)

If the DS9490R is already plugged in, unplug/replug it (or reboot) so the
'blacklist ds2490' + udev rule take effect. To unload the kernel module now
without rebooting:
    sudo modprobe -r ds2490 w1_smem wire
DONE
