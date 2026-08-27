#!/usr/bin/env bash

# Apply the prototype patch to a clean QEMU 11.1 checkout.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
project_dir="${MBL_DIR:-$HOME/QEMU/MBL}"
source_dir="${QEMU_SRC:-$project_dir/qemu-11.1-mbl}"
patch_file="$repo_dir/patches/qemu-11.1-mbl.patch"

[[ -f "$source_dir/configure" ]] || {
    printf 'QEMU source tree not found: %s\n' "$source_dir" >&2
    exit 1
}

git -C "$source_dir" apply --check "$patch_file"
git -C "$source_dir" apply "$patch_file"

printf 'Applied %s to %s\n' "$patch_file" "$source_dir"
