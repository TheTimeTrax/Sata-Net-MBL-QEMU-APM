#!/usr/bin/env bash

# Boot the external OpenWrt artifacts using QEMU user-mode networking.
set -euo pipefail

project_dir="${MBL_DIR:-$HOME/QEMU/MBL}"
build_dir="${QEMU_BUILD_DIR:-$project_dir/build-mbl-apm821xx}"

for path in "$build_dir/qemu-system-ppc" "$project_dir/mbl-uImage" \
            "$project_dir/mbl-qemu-apollo3g.dtb" "$project_dir/imagenhd.qcow2"; do
    [[ -e "$path" ]] || {
        printf 'Missing runtime artifact: %s\n' "$path" >&2
        exit 1
    }
done

drive_args=(
    -drive "file=$project_dir/imagenhd.qcow2,format=qcow2,if=ide,index=0"
)

if [[ -n "${MBL_SECOND_DISK:-}" ]]; then
    [[ -e "$MBL_SECOND_DISK" ]] || {
        printf 'Missing optional secondary disk: %s\n' "$MBL_SECOND_DISK" >&2
        exit 1
    }
    drive_args+=(
        -drive "file=$MBL_SECOND_DISK,format=qcow2,if=ide,index=1"
    )
fi

exec "$build_dir/qemu-system-ppc" \
    -machine mbl-apm821xx \
    -m 256M \
    -nographic \
    -kernel "$project_dir/mbl-uImage" \
    -dtb "$project_dir/mbl-qemu-apollo3g.dtb" \
    -append "console=ttyS0,115200 root=/dev/sda2 rw rootfstype=ext4" \
    "${drive_args[@]}" \
    -nic user,model=ppc4xx-emac
