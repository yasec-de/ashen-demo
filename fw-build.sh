#!/bin/sh
# Build ashen-fw (incl. submodules, dirty tree) in the buildns tmpfs; export ELF to cache/out.
set -e
DEMO=$(cd "$(dirname "$0")" && pwd)
mountpoint -q /dev/shm/ns || exec "$DEMO/buildns" run "$DEMO/fw-build.sh" "$@"
. "$DEMO/env.sh"
out=$("$DEMO/nix" build -L --no-link --print-out-paths "git+file://$DEMO/ashen-fw?submodules=1")
mkdir -p "$ASHEN_OUT"
rm -f "$ASHEN_OUT/ashen-fw.elf"
cp "/dev/shm/ns/.nix-portable$out/bin/ashen-fw" "$ASHEN_OUT/ashen-fw.elf"
echo "built $out -> $ASHEN_OUT/ashen-fw.elf"
