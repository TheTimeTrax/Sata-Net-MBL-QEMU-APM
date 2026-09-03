# Validation record

Validated on macOS with a local QEMU 11.1 build and OpenWrt 25.12.5 for
`apm821xx-sata/wd_mybooklive`.

Observed successful sequence:

1. Linux identifies the My Book Live 460EX platform and mounts ext4 root from
   the emulated SATA disk (`/dev/sda2`).
2. With a second IDE image at index 1, Linux enumerates both native SATA ports:
   `sda` exposes the root partitions and `sdb` exposes the secondary image
   partitions without SATA DMA timeouts.
3. The PPC4xx EMAC discovers the emulated PHY and reports link up.
4. DHCP traffic travels through EMAC, MAL, UIC and QEMU user networking.
5. After `/etc/init.d/network restart`, `br-lan` receives `10.0.2.15/24`.
6. DNS resolution through the QEMU user-mode DNS server (`10.0.2.3`) succeeds.
7. An HTTPS download with `uclient-fetch` succeeds.

Validated bridged sequence on macOS VMNet:

1. QEMU starts with `-nic vmnet-bridged,ifname=en2,model=ppc4xx-emac`.
2. The external DHCP server replies to the MBL MAC address.
3. `br-lan` receives the external lease (`10.0.0.128` during validation).
4. The guest can communicate with the external LAN gateway (`10.0.0.1`).

The EMAC model uses RX back-pressure with a retry timer. Queue flushing and
TX completion run in deferred bottom halves, preventing a MAL interrupt from
re-entering an active guest descriptor operation. This prevents duplicate
frames and stalls when a frame arrives before Linux has posted a MAL RX
descriptor.

The validation DTB omits the `tah-device` and `tah-channel` EMAC links. The
460EX TAH checksum accelerator is present in the source tree, but has no QEMU
implementation yet. Leaving it unattached forces Linux to calculate TCP/UDP
checksums in software.

The scripts use `br-lan`, not `eth0`, for DHCP because OpenWrt places the
physical device in that bridge.

These networking checks use a clean OpenWrt guest configuration. Custom
firewall, policy-routing, VPN, DNS-forwarding, or boot-time setup scripts must
be validated separately because they can intentionally alter or reject guest
traffic.
