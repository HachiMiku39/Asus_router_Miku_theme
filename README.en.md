# Hatsune Miku Theme + Wi-Fi Boost

[简体中文](README.md) · [English](README.en.md)

One ASUSWRT-Merlin software-center module combining a full Miku theme with local Wi-Fi power controls. No machine codes, activation keys, payment screens, or online licensing are required.

![Login preview](screenshots/login-desktop.png)

## Features

- Original artwork, Miku teal (`#39C5BB`) and pink accents, with the existing Merlin menus and settings.
- Full branded login artwork with its header, border and credits visible. Portrait layouts place the form below the complete image.
- A dedicated character banner above the toolbar, avoiding the original 54 px header crop.
- Independent 2.4 GHz / 5 GHz controls, temperature and driver power readings, calibration limits, read-only previews, local backups and restore.
- dBm and converted mW shown together for readings and sliders, a visible disclaimer, and a **Back to Software Center** button at the top of both tabs.
- Live telemetry every second: all discovered radio temperatures on a two-minute chart, connected-client counts, upload/download rates per band and combined totals. Sampling pauses in background tabs. Rates use driver counter deltas, include local traffic, and may be affected by hardware acceleration.
- One installed module with **Appearance** and **Wi-Fi Boost** tabs; reversible theme overlays and legacy-plugin rollback.

## Compatibility and installation

The target is **ARMv8 ASUSWRT-Merlin / KoolShare devices with an existing software center, DBus and compatible classic Merlin web interfaces**. Installation is no longer restricted by model name. The package contains scripts and web assets, with no model-specific executable.

| Feature | Compatibility |
| --- | --- |
| Miku theme | ARMv8 and the expected classic Merlin web interfaces; independent of radio chipset |
| Live monitoring | Automatically discovers radios, reordered bands, multiple 5 GHz radios and 6 GHz; readings require driver `wl` support |
| Power preview/apply/restore | A compatible Broadcom HND profile with exactly one 2.4 GHz and one 5 GHz radio; identity, schema, round-trip and helper checks must pass |
| Other chipsets, tri/quad-band or unknown calibration | Theme remains available; readable telemetry is shown; power actions are disabled with a reason |

**ARMv8 does not imply a universal calibration layout.** Hardware validation remains limited to RT-AX86U Pro / `3006.102.9_0`. Other devices are theoretically compatible through capability checks, not certified by this release. Tri-band/6 GHz discovery and UI are fixture-tested; their calibration writes are not supported. AArch64/arm64 and some ARMv8 CPUs running 32-bit kernels can be detected. See [COMPATIBILITY.md](COMPATIBILITY.md).

Download `mikuui-2.1.0.tar.gz` from [Releases](https://github.com/HachiMiku39/Asus_router_Miku_theme/releases), upload it through the software center's offline/manual installation page, then open the combined module. Apply the theme and refresh the browser.

Wi-Fi support requires Broadcom `wl`, the running calibration snapshot and the firmware's native `hndnvram.sh` interface. Install, status and preview do not alter radio power or reboot. **Applying changed power settings or restoring calibration requires confirmation and restarts the router.** Region, proxy, firewall, LAN/WAN, airtime-fairness and beamforming settings are preserved. Requested calibration limits do not guarantee the same live transmit power; regional and driver limits still apply.

Power calibration persists independently of USB storage. Disabling the theme, removing USB storage or uninstalling does not undo power changes; use the backup-restore action when needed.

## Backups

Backups remain on the router under `/jffs/mikuui-backups/`, protected by file hashes and a device-identity check. They are never exposed through the UI, included in the package, or uploaded to this repository. Existing associated legacy backups are migrated when the power compatibility check passes. Otherwise the backup captures the configuration before this module's first application, which is not necessarily an untouched factory configuration.

Legacy Wi-Fi Boost files and registration metadata are retained privately for rollback. Only its specific files are moved; shared resources are preserved. Uninstall restores the previous plugin when one existed, restores the firmware appearance, and retains private backups.

The Wi-Fi backend is a local implementation without a payment or activation mechanism. Legacy activation data is used only to locate an existing backup during migration and is never needed for a new installation.

## Build and verification

```sh
python3 -m unittest discover -s tests -v
python3 build.py
```

Packages and SHA-256 checksums are produced in `dist/`. Offline tests use synthetic calibration fixtures. Release notes distinguish actual UI, installation and read-only checks from unexecuted power writes or reboot tests.

Code licensing is in [LICENSE](LICENSE). Bundled artwork and trademarks are excluded from that license; see [ASSETS.md](ASSETS.md). Original artwork credit: **Art by Hanasa © CFM**.
