# OneWireViewer for Linux (DS9490R / USB)

A working, **buildable-from-source** packaging of Maxim/Analog's **OneWireViewer**
for modern Linux with the **DS9490R** USB 1‑Wire/iButton adapter.

The official `OneWireViewer-Linux.zip` was orphaned in the Maxim → Analog Devices
migration and is no longer downloadable anywhere (even the Wayback Machine kept
only the dead redirect). This repo reassembles a complete, working build from the
surviving open-source pieces and fixes everything needed to compile and run it on
a current JDK (tested on **OpenJDK 26**, Arch Linux, x86‑64).

> **Status:** builds clean, the native USB driver loads, the adapter enumerates as
> `DS9490` / ports `USB1..n`, and the GUI launches on JDK 26. Real device I/O
> requires a physical DS9490R (see *Verified vs. untested* below).

---

## What's inside

| Path | What it is |
|------|------------|
| `lib/OneWireAPI.jar` | The Dallas/Maxim 1‑Wire Java API (prebuilt, pure Java, arch‑independent). |
| `prebuilt/OneWireViewer.jar` | The OneWireViewer GUI, **already patched** for JDK 24+ (pure Java). |
| `src/onewireviewer/` | Full OneWireViewer **source** with the JDK‑26 patches applied (see *Patches*). |
| `src/pdkadapterusb/` | The DS9490R USB bridge: a `DSPortAdapter` (`PDKAdapterUSB.java`) + the libusb DS2490 native driver in C. This is the piece that only ever shipped in the lost zip. |
| `onewire.properties` | Registers `PDKAdapterUSB` so the viewer's adapter chooser lists the USB adapter. |
| `build.sh` | Builds the machine‑specific native lib (`libonewireUSB.so`) + adapter class. |
| `run.sh` | Runs the viewer straight from the repo (no install). |
| `install.sh` / `uninstall.sh` | System‑wide install to `/opt` + launcher + udev rule + module blacklist. |

### Architecture

```
 OneWireViewer.jar  (Swing GUI)
        │  uses
 OneWireAPI.jar     (com.dalsemi.onewire.* — Java 1-Wire API)
        │  DSPortAdapter SPI
 PDKAdapterUSB.class  ── System.loadLibrary("onewireUSB") ──►  libonewireUSB.so
                                                                 │  libusb-0.1
                                                                 ▼
                                                        DS9490R (USB 04fa:2490)
```

The stock `OneWireAPI.jar` only ships **serial / network / Windows‑TMEX** adapters
— it has **no USB adapter**. `PDKAdapterUSB` is the missing Linux USB
`DSPortAdapter`; its JNI methods forward 1:1 to the Public Domain Kit functions
(`owTouchReset`, `owBlock`, `owFirst`/`owNext`, `owSerialNum`, `owLevel`, …) which
drive the DS2490 over libusb.

---

## Requirements

- A **JDK** (for `javac` + JNI headers). Arch: `pacman -S jdk-openjdk`.
- **libusb‑0.1** compatibility headers (`usb.h`).
  - Arch: `pacman -S libusb-compat base-devel`
  - Debian/Ubuntu: `apt install libusb-dev build-essential default-jdk`
  - Fedora: `dnf install libusb-compat-0.1-devel @development-tools java-latest-openjdk-devel`
- A **DS9490R** USB 1‑Wire adapter (USB id `04fa:2490`).

---

## Quick start

```bash
# 1. build the machine-specific native driver (and adapter class)
./build.sh                 # or:  ./build.sh --with-viewer   to also recompile the GUI from source

# 2a. try it without installing
./run.sh

# 2b. ...or install system-wide
sudo ./install.sh
onewireviewer              # launcher on PATH; also appears in your app menu
```

### Before plugging in the adapter

`install.sh` adds `blacklist ds2490` so the kernel's 1‑Wire USB master doesn't grab
the device (libusb needs it). After installing, either **reboot**, or unload the
module live and replug the adapter:

```bash
sudo modprobe -r ds2490 w1_smem wire      # ignore "not loaded" errors
# unplug & replug the DS9490R
```

In the viewer's adapter chooser pick **DS9490 → USB1**.

---

## How it works on disk after install

```
/opt/onewireviewer/            OneWireAPI.jar, OneWireViewer.jar,
                               libonewireUSB.so, classes/…/PDKAdapterUSB.class,
                               onewire.properties
/usr/local/bin/onewireviewer   launcher (runs from ~/.config/onewireviewer so
                               user settings stay user-owned)
/etc/udev/rules.d/60-ds9490.rules        grants the local user access to 04fa:2490
/etc/modprobe.d/onewire-ds9490.conf      blacklist ds2490
~/.config/onewireviewer/       per-user workdir: onewire.properties + saved settings
```

---

## Patches applied (why the original won't build/run on JDK 26)

The upstream code is from ~2003–2006. Recompiling and running it on a current JDK
required these fixes (all already applied in this repo):

1. **`System.setSecurityManager(null)` removed** — the Security Manager was removed
   in JDK 24+ and the call throws `UnsupportedOperationException`.
   (`src/onewireviewer/src/OneWireViewer.java`)
2. **`enum` used as a variable name** → renamed to `viewerEnum`. `enum` has been a
   reserved keyword since Java 5. (`OneWireViewer.java`)
3. **bare `yield()` calls** → `Thread.yield()`. `yield` became a restricted
   identifier in Java 13. (`ThreadTimer.java`)
4. **Native build for GCC 14+/16** — the 2005 C omits `#include <string.h>` etc.;
   modern GCC treats implicit declarations as errors. `build.sh` force‑includes the
   standard headers and demotes implicit‑declaration back to a warning.
5. **`javah` is gone** (removed in JDK 10) — `build.sh` generates the JNI header with
   `javac -h` instead.
6. **Makefile retargeted** — the recovered kit shipped a macOS Makefile
   (`.jnilib`, JavaVM/IOKit frameworks). `build.sh` builds a Linux `.so` linked
   against `-lusb`.

To diff against the untouched original, see the upstream sources noted in *Provenance*.

---

## Provenance & security

- **OneWireAPI / OneWireViewer** — from the official `owapi_1_10` SDK, mirrored at
  `github.com/concord-consortium/BlockModel` (`owapi_1_10/`).
- **PDKAdapterUSB** (the USB driver) — recovered from a public 2005 mirror,
  `http://globalreset.org/files/distribution/PDKAdapterUSB.tar.gz`, because the
  official zip is gone.
- **Genuine‑zip SHA‑256** (from the AUR `onewireviewer` PKGBUILD, for verifying any
  copy you find elsewhere): `fe6dfce35e093a2e36abc4c2a7f612a01b0680bafb662212acd5f9bf1bec27d2`

The recovered USB driver source was audited before use: **no networking, no process
execution, no filesystem access, no obfuscation, no Java reflection tricks.** It
opens **only** the Maxim DS2490 (`idVendor==0x04FA && idProduct==0x2490`) and does
standard libusb device I/O. Its shared PDK files match an independently‑sourced
mirror (AriZuu/OneWire) except for benign additions (six libusb error codes/strings).
It runs as your user, not root, and only talks to a DS9490R you physically plug in.

See `LICENSE` for licensing (MIT‑style Dallas Semiconductor license).

---

## Verified vs. untested

- ✅ Builds clean on OpenJDK 26 (native lib, adapter class, GUI).
- ✅ `libonewireUSB.so` loads; adapter enumerates (`name=DS9490`, `ports=[USB1..USB14]`).
- ✅ GUI launches and stays running.
- ⚠️ **Real device I/O not exercised here** — no DS9490R was attached during build.
  Confirm read/search/temperature once your adapter is connected.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `UnsatisfiedLinkError: no onewireUSB` | `libonewireUSB.so` not on `java.library.path`. Re‑run `./build.sh`; use `run.sh`/the installed launcher (they set it). |
| Adapter chooser shows no DS9490 | `onewire.properties` not in the working dir. The launcher copies it to `~/.config/onewireviewer/`; check it's there. |
| `usb_claim_interface` / permission errors | Kernel `ds2490` still bound, or udev rule not applied. `sudo modprobe -r ds2490 w1_smem wire`, replug, and ensure `/etc/udev/rules.d/60-ds9490.rules` exists (`sudo udevadm control --reload-rules`). |
| `usb.h: No such file` during build | Install `libusb-compat` (Arch) / `libusb-dev` (Debian). |
| Want to rebuild the GUI too | `./build.sh --with-viewer`. |

---

## Credits

OneWireViewer, the 1‑Wire API, and the Public Domain Kit are © Dallas Semiconductor
/ Maxim Integrated / Analog Devices. This repo only re‑packages and modernizes them
so they build and run on current Linux.
