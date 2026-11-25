#!/usr/bin/env bash
# Cross-build crun with the krun handler for the board, from a committed ref of the crun
# submodule (default: its pinned commit), in the buildns tmpfs. Exports krun/crun to the build
# outputs; installed as krun, crun runs containers in libkrun microVMs (it dlopens libkrun.so.1).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
mountpoint -q /dev/shm/ns || exec "$HERE/../buildns" run "$HERE/build-crun.sh" "$@"
DEMO=$(cd "$HERE/.." && pwd)
. "$DEMO/env.sh"
REPO=$HERE/../crun
REF=${1:-HEAD}
SRC=/dev/shm/ns/crun-src
EXPORT=$ASHEN_OUT/krun
if [[ -z "${IN_NIX_SHELL:-}" ]]; then
	rev=$(git -C "$REPO" rev-parse "$REF")
	if [[ "$(cat "$SRC/.rev" 2>/dev/null)" != "$rev" ]]; then
		rm -rf "$SRC"; mkdir -p "$SRC"
		git -C "$REPO" archive "$rev" | tar -mx -C "$SRC"
		# libocispec is a submodule (with its own), which git archive leaves out
		git -C "$REPO/libocispec" ls-files --recurse-submodules -z |
			(cd "$REPO/libocispec" && tar --null -T - -cf -) | tar -mx -C "$SRC/libocispec"
		printf '#define GIT_VERSION "%s"\n' "$rev" > "$SRC/.tarball-git-version.h"
		echo "$rev" > "$SRC/.rev"
	fi
	cd "$SRC"
	exec "$HERE/../nix" develop --impure -f "$HERE/crun-shell.nix" -c "$HERE/build-crun.sh" "$rev"
fi
cd "$SRC"
[[ -x configure ]] || ./autogen.sh
# libkrun.h only provides the KRUN_* constants: the handler dlopen()s libkrun at runtime. Take it
# from the libkrun crun loads (the submodule's 1.x branch), not 2.0's generated header.
./configure --host=aarch64-unknown-linux-gnu --with-libkrun --enable-embedded-blake3 \
	--disable-criu CPPFLAGS="-I$HERE/../libkrun/include" \
	LDFLAGS="-Wl,--dynamic-linker=/lib/ld-linux-aarch64.so.1"
make -j"$(nproc)"
mkdir -p "$EXPORT"
cp crun "$EXPORT/crun"
f=$EXPORT/crun
echo "$f: needs $(readelf -V "$f" | grep -oE 'GLIBC_[0-9.]+' | sort -uV | tail -1)," \
	"interp $(readelf -l "$f" | sed -n 's/.*interpreter: \(.*\)]/\1/p')"
