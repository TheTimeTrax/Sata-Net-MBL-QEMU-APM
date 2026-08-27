# QEMU APM821xx / WD My Book Live prototype

Experimental QEMU 11.1 machine for booting OpenWrt on the PowerPC APM821xx
platform used by the Western Digital My Book Live.

This repository deliberately contains only the project-specific work:

- a patch against QEMU 11.1;
- the My Book Live Device Tree source;
- reproducible build and launch scripts; and
- validation notes.

It does **not** include QEMU itself, OpenWrt images, disk overlays, firmware,
or generated build files.

## Current result

OpenWrt 25.12.5 (`apm821xx-sata/wd_mybooklive`) boots from an ext4 QCOW2 disk.
The emulated PPC4xx EMAC, MAL and UIC path works with QEMU user-mode networking:
OpenWrt receives a DHCP lease (`10.0.2.15`) on `br-lan` and can reach the
user-mode gateway (`10.0.2.2`).

The implementation remains a hardware prototype, not a cycle-accurate MBL
emulator.

## Requirements

- macOS with MacPorts dependencies used by the local QEMU build;
- a clean QEMU 11.1 source checkout;
- an OpenWrt kernel/uImage, ext4 disk image and compiled MBL DTB kept outside
  this repository.

## Apply the patch and build

Set `MBL_DIR` to the directory containing the QEMU source tree, or use the
default `~/QEMU/MBL` layout:

```sh
export MBL_DIR="$HOME/QEMU/MBL"
./scripts/apply-qemu-patch.sh
./scripts/build-mbl-qemu.sh
```

The patch is intended for QEMU 11.1. It adds the `mbl-apm821xx` PPC machine,
APM821xx SATA/DMA support and a PPC4xx EMAC/MAL integration.

## Run OpenWrt

Place these external artifacts in `$MBL_DIR`:

- `mbl-uImage`
- `mbl-qemu-apollo3g.dtb` (compile from `dts/mbl-apollo3g.dts`)
- `salida.qcow2`

Then run:

```sh
export MBL_DIR="$HOME/QEMU/MBL"
./scripts/run-openwrt.sh
```

Inside OpenWrt, restart the network configuration if needed and verify:

```sh
/etc/init.d/network restart
ip addr show dev br-lan
ping -c 3 10.0.2.2
```

## License

The QEMU-derived changes are provided under GPL-2.0-or-later, consistent with
the upstream QEMU source files they modify. See the upstream QEMU project for
the complete license text.
