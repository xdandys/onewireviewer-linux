#!/usr/bin/env bash
#
# run.sh - Launch OneWireViewer straight from this repo (no system install).
# Requires ./build.sh to have been run first.
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$ROOT/build/libonewireUSB.so" ] || { echo "Native lib missing - run ./build.sh first." >&2; exit 1; }

# per-user writable workdir so saved settings + onewire.properties are user-owned
WORK="${XDG_CONFIG_HOME:-$HOME/.config}/onewireviewer"
mkdir -p "$WORK"
[ -f "$WORK/onewire.properties" ] || cp "$ROOT/onewire.properties" "$WORK/"
cd "$WORK"

exec java --enable-native-access=ALL-UNNAMED \
  -Djava.library.path="$ROOT/build" \
  -cp "$ROOT/lib/OneWireAPI.jar:$ROOT/build/OneWireViewer.jar:$ROOT/build/classes" \
  OneWireViewer "$@"
