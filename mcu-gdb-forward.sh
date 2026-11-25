#!/bin/sh
# SSH counterpart of ashen-fw/run-openocd.sh: start the board's OpenOCD (bit-banged SWD) and
# forward its gdb port to localhost:3333. Stays in the foreground; Ctrl-C stops OpenOCD.
set -e
DEMO=$(cd "$(dirname "$0")" && pwd)
. "$DEMO/env.sh"
H=$("$DEMO/bssh" --host)
exec ssh ${ASHEN_SSH_KEY:+-i "$ASHEN_SSH_KEY"} -L 3333:127.0.0.1:3333 root@"$H" \
	'pkill -x openocd 2>/dev/null; trap "pkill -x openocd" EXIT INT TERM; arduino-debug'
