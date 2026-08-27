#!/usr/bin/env bash

# Build QEMU 11.1 with the APM821xx/My Book Live prototype machine.
set -euo pipefail

project_dir="${MBL_DIR:-$HOME/QEMU/MBL}"
source_dir="${QEMU_SRC:-$project_dir/qemu-11.1-mbl}"
tools_bin="${MBL_TOOLS_BIN:-$project_dir/mbl-build-tools/bin}"
build_dir="${QEMU_BUILD_DIR:-$project_dir/build-mbl-apm821xx}"

for path in "$source_dir/configure" "$tools_bin/python" \
            /opt/local/bin/clang-mp-17 /opt/local/bin/clang++-mp-17; do
    [[ -e "$path" ]] || {
        printf 'Missing prerequisite: %s\n' "$path" >&2
        exit 1
    }
done

mkdir -p "$build_dir"
cd "$build_dir"

PKG_CONFIG_PATH="/opt/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}" \
PATH="$tools_bin:$PATH" "$source_dir/configure" \
    --enable-fdt=internal \
    --enable-slirp \
    --target-list=ppc-softmmu \
    --cc=/opt/local/bin/clang-mp-17 \
    --cxx=/opt/local/bin/clang++-mp-17 \
    --objcc=/opt/local/bin/clang-mp-17 \
    --host-cc=/opt/local/bin/clang-mp-17 \
    --python="$tools_bin/python" \
    --disable-werror --disable-docs --disable-gtk --disable-sdl --disable-cocoa \
    --disable-vnc --disable-spice --disable-curses --disable-opengl

PATH="$tools_bin:$PATH" ninja qemu-system-ppc
./qemu-system-ppc -machine help | grep -F 'mbl-apm821xx'
