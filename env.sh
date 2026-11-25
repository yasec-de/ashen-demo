# Sourced by the demo scripts once they have set $DEMO to the repo root. Nothing here looks
# outside the repo: everything else comes from the environment or from $DEMO/local.env
# (per-machine, not in git; see local.env.example).
[ -f "$DEMO/local.env" ] && . "$DEMO/local.env"
# Build outputs (out/) and downloaded tools (bin/).
ASHEN_CACHE=${ASHEN_CACHE:-$DEMO/cache}
ASHEN_OUT=$ASHEN_CACHE/out
# ASHEN_LINUX: ashen-linux checkout to build the demo kernel from (kernel/build.sh).
# ASHEN_SSH_KEY: private key for root@board; unset uses ssh's own defaults.
# BOARD: board address; unset tries wired, then Wi-Fi (see bssh).
