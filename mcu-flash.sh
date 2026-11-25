#!/bin/sh
# Flash an ashen-fw ELF onto the UNO Q's MCU through the board's own OpenOCD (bit-banged SWD),
# verify, and reset. The keystore page (top of flash, NOLOAD) is not touched.
#   mcu-flash.sh [elf]   (default: ashen-fw.elf in the build outputs, see fw-build.sh)
set -e
DEMO=$(cd "$(dirname "$0")" && pwd)
. "$DEMO/env.sh"
ELF=${1:-$ASHEN_OUT/ashen-fw.elf}
"$DEMO/bscp" "$ELF" /var/tmp/ashen-fw.elf
"$DEMO/bssh" 'pkill -x openocd; cd /opt/openocd && bin/openocd -s /opt/openocd -f openocd_gpiod.cfg \
	-c "reset_config srst_only srst_push_pull" -c "program /var/tmp/ashen-fw.elf verify reset exit" 2>&1 |
	grep -E "Verified|Error|wrong"'
