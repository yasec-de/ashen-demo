#!/bin/sh
# Rootless nix for this VM: nix-portable, store in the buildns tmpfs (see demo/buildns for why
# not virtiofs). Re-execs itself inside the build namespace when called from outside.
DEMO=$(cd "$(dirname "$0")" && pwd)
mountpoint -q /dev/shm/ns || exec "$DEMO/buildns" run "$DEMO/nix" "$@"
. "$DEMO/env.sh"
# nix-portable itself: a pinned release, fetched into the cache on first use.
NP=$ASHEN_CACHE/bin/nix-portable
NP_URL=https://github.com/DavHau/nix-portable/releases/download/v012/nix-portable-x86_64
NP_SHA256=b409c55904c909ac3aeda3fb1253319f86a89ddd1ba31a5dec33d4a06414c72a
if [ ! -x "$NP" ]; then
	mkdir -p "$(dirname "$NP")"
	curl -fsSL -o "$NP.part" "$NP_URL"
	echo "$NP_SHA256  $NP.part" | sha256sum -c --quiet || { rm -f "$NP.part"; exit 1; }
	chmod +x "$NP.part" && mv "$NP.part" "$NP"
fi
export NP_LOCATION=/dev/shm/ns NP_RUNTIME=bwrap
export TMPDIR=/dev/shm/ns/tmp XDG_CACHE_HOME=/dev/shm/ns/xdg
# A real HOME: without one, tools in `nix develop` shells write to /homeless-shelter, which
# makes every concurrent nix build (sandbox off) refuse to run.
export HOME=/dev/shm/ns/home
mkdir -p "$HOME"
# The VM's hard open-file limit is 4096; nix's default parallel substitution exceeds it.
export NIX_CONFIG="http-connections = 8
max-substitution-jobs = 4
sandbox = false"
# Without the sandbox, builds that touch $HOME (/homeless-shelter) leave it behind and nix then
# refuses every later build; it's scratch, so drop it.
HS=/dev/shm/ns/.nix-portable/emptyroot/homeless-shelter
rm -rf "$HS"
[ "$1" = build ] || exec "$NP" nix --extra-experimental-features 'nix-command flakes' "$@"
# A builder that writes to $HOME mid-run makes nix refuse the next derivation of the same run.
# Everything built so far stays in the store, so clear it and go on.
for try in 1 2 3 4 5 6 7 8; do
	"$NP" nix --extra-experimental-features 'nix-command flakes' "$@" && exit 0
	rc=$?
	[ -e "$HS" ] || exit $rc
	echo "nix: $HS appeared during the build; removing it and retrying ($try)" >&2
	rm -rf "$HS"
done
exit $rc
