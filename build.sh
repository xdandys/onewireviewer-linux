#!/usr/bin/env bash
#
# build.sh - Build the machine-specific native pieces of OneWireViewer-Linux.
#
# Produces (under ./build):
#   - libonewireUSB.so   the JNI + libusb DS2490 driver for the DS9490R
#   - classes/...        the compiled PDKAdapterUSB adapter class
#   - OneWireViewer.jar  (copied from prebuilt/, or rebuilt with --with-viewer)
#
# Usage:
#   ./build.sh                build native driver, use prebuilt viewer jar
#   ./build.sh --with-viewer  also recompile OneWireViewer.jar from source
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$ROOT/build"
OWAPI="$ROOT/lib/OneWireAPI.jar"

say(){ printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die(){ printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# --- locate a JDK that has the JNI headers -----------------------------------
command -v javac >/dev/null || die "javac not found. Install a JDK (Arch: pacman -S jdk-openjdk)."
JHOME="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")}"
[ -f "$JHOME/include/jni.h" ] || die "jni.h not found under $JHOME/include - point JAVA_HOME at a full JDK."
say "JDK:           $JHOME"

# --- libusb-0.1 compatibility header (usb.h) ---------------------------------
USBINC=""
for d in /usr/include /usr/local/include; do [ -f "$d/usb.h" ] && USBINC="$d" && break; done
[ -n "$USBINC" ] || die "usb.h (libusb-0.1) missing. Arch: pacman -S libusb-compat | Debian/Ubuntu: apt install libusb-dev"
say "libusb-0.1:    $USBINC/usb.h"
command -v gcc >/dev/null || die "gcc not found (Arch: pacman -S base-devel)."

rm -rf "$BUILD"; mkdir -p "$BUILD/classes" "$BUILD/jni"

# --- compile the Java adapter and emit a matching JNI header -----------------
say "Compiling PDKAdapterUSB.java"
javac -d "$BUILD/classes" -h "$BUILD/jni" -classpath "$OWAPI" \
  "$ROOT"/src/pdkadapterusb/java/src/com/dalsemi/onewire/adapter/PDKAdapterUSB.java
# native code does #include "PDKAdapterUSB.h"; provide the freshly generated one first on the include path
cp "$BUILD/jni/com_dalsemi_onewire_adapter_PDKAdapterUSB.h" "$BUILD/jni/PDKAdapterUSB.h"

# --- compile the native libusb DS2490 driver ---------------------------------
say "Compiling native libusb DS2490 driver"
NAT="$ROOT/src/pdkadapterusb/native"
INC="-I$BUILD/jni -I$JHOME/include -I$JHOME/include/linux -I$NAT -I$USBINC"
# 2005-era C: force-include standard headers and relax modern implicit-decl errors (GCC 14+/16)
COMPAT="-include string.h -include stdlib.h -include unistd.h -Wno-error=implicit-function-declaration -Wno-implicit-function-declaration"
OBJS=()
for c in crcutil libusbds2490 libusbllnk libusbnet libusbses libusbtran owerr PDKAdapterUSB; do
  gcc -O2 -fPIC -fno-common $COMPAT $INC -c "$NAT/$c.c" -o "$BUILD/$c.o"
  OBJS+=("$BUILD/$c.o")
done

say "Linking libonewireUSB.so"
gcc -shared -o "$BUILD/libonewireUSB.so" "${OBJS[@]}" -lusb
file "$BUILD/libonewireUSB.so" | sed 's/^/    /'

# --- viewer jar: prebuilt (default) or rebuilt from source -------------------
if [ "${1:-}" = "--with-viewer" ]; then
  say "Rebuilding OneWireViewer.jar from source"
  VB="$BUILD/viewer"; rm -rf "$VB"; mkdir -p "$VB"
  javac -encoding ISO-8859-1 -classpath "$OWAPI" -d "$VB" "$ROOT"/src/onewireviewer/src/*.java
  cp -r "$ROOT"/src/onewireviewer/images "$VB"/
  ( cd "$VB" && jar cfe "$BUILD/OneWireViewer.jar" OneWireViewer -C "$VB" . )
else
  cp "$ROOT/prebuilt/OneWireViewer.jar" "$BUILD/OneWireViewer.jar"
fi

say "Build complete -> $BUILD"
echo
echo "  Run without installing:  ./run.sh"
echo "  Install system-wide:     sudo ./install.sh"
