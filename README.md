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
OpenWrt receives a DHCP lease (`10.0.2.15`) on `br-lan`, resolves DNS names,
and downloads files over HTTPS.

The supplied QEMU-specific Device Tree deliberately leaves the APM821xx TAH
checksum accelerator unattached from EMAC. TAH checksum offload is not yet
implemented in the QEMU model; omitting the link makes the Linux driver use
software TCP/UDP checksums. The TAH node remains in the tree to describe the
real hardware for future work.

The implementation remains a hardware prototype, not a cycle-accurate MBL
emulator.

## Requirements

- macOS with MacPorts dependencies used by the local QEMU build;
- a clean QEMU 11.1 source checkout;
- an OpenWrt kernel/uImage and ext4 disk image kept outside this repository.

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

Compile the supplied Device Tree and place the external runtime artifacts in
`$MBL_DIR`:

```sh
dtc -I dts -O dtb \
  -o "$MBL_DIR/mbl-qemu-apollo3g.dtb" \
  dts/mbl-apollo3g.dts
```

The runtime files are:

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
nslookup downloads.openwrt.org 10.0.2.3
uclient-fetch -4 -O /tmp/packages.adb \
  https://downloads.openwrt.org/releases/25.12.5/packages/powerpc_464fp/base/packages.adb
ls -lh /tmp/packages.adb
```

## License

The QEMU-derived changes are provided under GPL-2.0-or-later, consistent with
the upstream QEMU source files they modify. See the upstream QEMU project for
the complete license text.
