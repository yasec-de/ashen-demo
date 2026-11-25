#!/usr/bin/env bash
# Build the zeroize wipe payload (crash-kernel image) with the kernel cross toolchain, in the
# buildns tmpfs, from the zeroize submodule. Exports zeroize/Image to the build outputs.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
mountpoint -q /dev/shm/ns || exec "$HERE/buildns" run "$HERE/build-payload.sh" "$@"
[[ -n "${IN_NIX_SHELL:-}" ]] || exec "$HERE/nix" develop "path:$HERE/kernel" -c "$HERE/build-payload.sh" "$@"
DEMO=$HERE
. "$DEMO/env.sh"
B=/dev/shm/ns/zeroize
rm -rf "$B"; mkdir -p "$B"
cp "$HERE"/zeroize/{Makefile,payload.c,payload.ld,start.S} "$B/"
make -C "$B" EXTRA_CFLAGS="${EXTRA_CFLAGS:-}"
mkdir -p "$ASHEN_OUT/zeroize"
cp "$B/Image" "$ASHEN_OUT/zeroize/Image"
aarch64-linux-gnu-nm -n "$B/payload.elf" | grep -E ' _end$| payload_main$'
