# Validation record

Validated on macOS with a local QEMU 11.1 build and OpenWrt 25.12.5 for
`apm821xx-sata/wd_mybooklive`.

Observed successful sequence:

1. Linux identifies the My Book Live 460EX platform and mounts ext4 root from
   the emulated SATA disk.
2. The PPC4xx EMAC discovers the emulated PHY and reports link up.
3. DHCP traffic travels through EMAC, MAL, UIC and QEMU user networking.
4. After `/etc/init.d/network restart`, `br-lan` receives `10.0.2.15/24`.
5. DNS resolution through the QEMU user-mode DNS server (`10.0.2.3`) succeeds.
6. An HTTPS download with `uclient-fetch` succeeds.

The validation DTB omits the `tah-device` and `tah-channel` EMAC links. The
460EX TAH checksum accelerator is present in the source tree, but has no QEMU
implementation yet. Leaving it unattached forces Linux to calculate TCP/UDP
checksums in software.

The scripts use `br-lan`, not `eth0`, for DHCP because OpenWrt places the
physical device in that bridge.
