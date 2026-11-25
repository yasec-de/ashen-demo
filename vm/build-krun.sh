#!/usr/bin/env bash
# Cross-build libkrun (with memaction-secret support) for the board, from a committed ref of the
# libkrun submodule, in the buildns tmpfs using the cross-build shell in libkrun-shell/.
#   build-krun.sh [REF]   REF defaults to the submodule's pinned commit (stable-1.19.x-crash-memaction):
#                         the libkrun.so.1 that crun loads to run ashen-galene-vm.
#                         crash-memaction-krunwipe (2.0-dev) exports libkrun.so.2 and the old
#                         krunwipe launcher.
# Exports to krun/ in the build outputs.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
mountpoint -q /dev/shm/ns || exec "$HERE/../buildns" run "$HERE/build-krun.sh" "$@"
DEMO=$(cd "$HERE/.." && pwd)
. "$DEMO/env.sh"
REPO=$HERE/../libkrun
REF=${1:-HEAD}
SRC=/dev/shm/ns/libkrun-src
EXPORT=$ASHEN_OUT/krun
if [[ -z "${IN_NIX_SHELL:-}" ]]; then
	rev=$(git -C "$REPO" rev-parse "$REF")
	if [[ "$(cat "$SRC/.rev" 2>/dev/null)" != "$rev" ]]; then
		rm -rf "$SRC"; mkdir -p "$SRC"
		git -C "$REPO" archive "$rev" | tar -x -C "$SRC"
		# libkrun main's cross-build shell (the stable branch has none), pinned here
		cp "$HERE/libkrun-shell/flake.nix" "$HERE/libkrun-shell/flake.lock" "$SRC/"
		echo "$rev" > "$SRC/.rev"
	fi
	cd "$SRC"
	exec "$HERE/../nix" develop "path:$SRC" -c "$HERE/build-krun.sh" "$rev"
fi
export CARGO_HOME=/dev/shm/ns/cargo
# 1.x builds the guest init from C, statically, with $CC_LINUX
export CC_LINUX="$CROSS_CC -L$CROSS_STATIC_LIBS"
cd "$SRC"
cargo build --release --target "$CROSS_TARGET" -p libkrun --features net
mkdir -p "$EXPORT"
lib="target/$CROSS_TARGET/release/libkrun.so"
soname=$(readelf -d "$lib" | sed -n 's/.*soname: \[\(.*\)\]/\1/p')
cp "$lib" "$EXPORT/$soname"
built=("$EXPORT/$soname")
if [[ -d examples/krunwipe ]]; then
	(cd examples/krunwipe && cargo build --release --target "$CROSS_TARGET")
	cp "examples/target/$CROSS_TARGET/release/krunwipe" "$EXPORT/krunwipe"
	built+=("$EXPORT/krunwipe")
fi
for f in "${built[@]}"; do
	echo "$f: needs $(readelf -V "$f" | grep -oE 'GLIBC_[0-9.]+' | sort -uV | tail -1)," \
		"interp $(readelf -l "$f" | sed -n 's/.*interpreter: \(.*\)]/\1/p')"
done
