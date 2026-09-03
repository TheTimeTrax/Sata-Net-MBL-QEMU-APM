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

Each user must obtain, create, and validate their own OpenWrt or alternative
disk image. Booting, modifying, or using any image is entirely at that user's
own risk and responsibility. Do not use an image containing data you cannot
afford to lose.

## Current result

OpenWrt 25.12.5 (`apm821xx-sata/wd_mybooklive`) boots from an ext4 QCOW2 disk.
The two native SATA ports can be populated simultaneously: the root disk is
available as `sda` and a second image as `sdb`.
The emulated PPC4xx EMAC, MAL and UIC path works with QEMU user-mode networking:
OpenWrt receives a DHCP lease (`10.0.2.15`) on `br-lan`, resolves DNS names,
and downloads files over HTTPS when using a clean guest network configuration.

The same EMAC/MAL model has also been validated with macOS VMNet bridged mode:
OpenWrt receives a lease from an external DHCP server and is reachable as a
peer on that LAN. This requires a QEMU build with VMNet support and a suitable
host interface, for example `en2`.

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
shared APM821xx SATA/DMA support for both native ports, and a PPC4xx
EMAC/MAL integration. RX queue flushing and TX completion are deferred out of
the MAL interrupt path to avoid re-entering guest descriptor processing.

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
- `imagenhd.qcow2`

To attach an optional second disk to SATA1, set `MBL_SECOND_DISK` to its
QCOW2 path before running the launch script:

```sh
MBL_SECOND_DISK="$MBL_DIR/imagenhd2.qcow2" ./scripts/run-openwrt.sh
```

Linux should report the two images as `sda` and `sdb`; the default root option
continues to use `/dev/sda2`.

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

## Bridged networking on macOS

For a guest address supplied by the physical LAN DHCP server, replace the
final `-nic user,model=ppc4xx-emac` option with:

```sh
-nic vmnet-bridged,ifname=en2,model=ppc4xx-emac
```

Run QEMU with the privileges required by the local VMNet installation. Replace
`en2` with the active host interface. Confirm in OpenWrt with
`ip addr show dev br-lan`.

## License

The QEMU-derived changes are provided under GPL-2.0-or-later, consistent with
the upstream QEMU source files they modify. See the upstream QEMU project for
the complete license text.
