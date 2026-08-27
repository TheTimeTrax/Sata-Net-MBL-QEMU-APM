# Sata-Net-MBL-QEMU-APM
# QEMU APM821xx / WD My Book Live prototype

Experimental QEMU 11.1 machine for booting OpenWrt on the PowerPC APM821xx platform used by the Western Digital My Book Live.

## Status

OpenWrt 25.12.5 for `apm821xx-sata/wd_mybooklive` boots from an ext4 disk image.

Implemented and validated:

- APM821xx / My Book Live QEMU machine
- SATA and DMA path sufficient to mount the OpenWrt root filesystem
- PPC4xx EMAC, MAL and UIC integration
- PHY detection and link state
- DHCP with QEMU user-mode networking
- Bridged networking through macOS `vmnet-bridged`

Example validated lease:

```text
br-lan: 10.0.2.15/24
```

This is a hardware prototype, not a cycle-accurate emulator.

## Repository contents

- `patches/qemu-11.1-mbl.patch` — patch for QEMU 11.1
- `dts/mbl-apollo3g.dts` — My Book Live Device Tree source
- `scripts/apply-qemu-patch.sh` — applies the patch to QEMU
- `scripts/build-mbl-qemu.sh` — builds the PPC QEMU binary
- `scripts/run-openwrt.sh` — starts OpenWrt with user-mode networking
- `docs/VALIDATION.md` — validation record

QEMU source code, OpenWrt images, QCOW2 disks, logs and generated build output are intentionally excluded.

## Build

Expected local layout:

```text
~/QEMU/MBL/
├── qemu-11.1-mbl/
├── mbl-build-tools/
└── github-mbl-apm821xx/
```

```sh
export MBL_DIR="$HOME/QEMU/MBL"

cd "$MBL_DIR/github-mbl-apm821xx"
./scripts/apply-qemu-patch.sh
./scripts/build-mbl-qemu.sh
```

## Run OpenWrt

Keep these external artifacts in `$MBL_DIR`:

```text
mbl-uImage
mbl-qemu-apollo3g.dtb
salida.qcow2
```

Compile the DTB from `dts/mbl-apollo3g.dts`, then run:

```sh
export MBL_DIR="$HOME/QEMU/MBL"
./scripts/run-openwrt.sh
```

Inside OpenWrt:

```sh
/etc/init.d/network restart
ip addr show dev br-lan
ping -c 3 10.0.2.2
```

## Bridged networking on macOS

The local QEMU build supports `vmnet-bridged`.

```sh
sudo ./build-mbl-apm821xx-restart/qemu-system-ppc \
  -machine mbl-apm821xx \
  -m 256M \
  -nographic \
  -kernel mbl-uImage \
  -dtb mbl-qemu-apollo3g.dtb \
  -append "console=ttyS0,115200 root=/dev/sda2 rw rootfstype=ext4" \
  -drive file=salida.qcow2,format=qcow2,if=ide \
  -nic vmnet-bridged,ifname=en0,model=ppc4xx-emac
```

Replace `en0` with the physical macOS network interface in use.

## License

SPDX-License-Identifier: GPL-2.0-or-later

This project modifies and adds code integrated with QEMU. It is distributed under the GNU General Public License, version 2 or later, consistent with QEMU’s licensing.
