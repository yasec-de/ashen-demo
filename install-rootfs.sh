#!/bin/sh
# Copy demo/rootfs/ onto the board (files only, existing config in /etc/default/ashen is kept)
# and reload systemd. Usage: install-rootfs.sh
set -e
DEMO=$(cd "$(dirname "$0")" && pwd)
. "$DEMO/env.sh"
B=$DEMO/bssh
cd "$DEMO/rootfs"
tar -cf - --owner=0 --group=0 --exclude=./etc/default/ashen . |
	$B 'tar -C / --keep-directory-symlink --no-overwrite-dir -xf - && systemctl daemon-reload'
$B 'test -e /etc/default/ashen' || tar -cf - --owner=0 --group=0 ./etc/default/ashen |
	$B 'tar -C / --keep-directory-symlink --no-overwrite-dir -xf -'
# Wipe payload (crash kernel) and its staging unit, from zeroize/ and its build output
$B 'install -d /usr/lib/zeroize'
"$DEMO/bscp" "$ASHEN_OUT/zeroize/Image" "$DEMO/zeroize/service/zeroize-stage.sh" /usr/lib/zeroize/
"$DEMO/bscp" "$DEMO/zeroize/service/zeroize-stage.service" /etc/systemd/system/
"$DEMO/bscp" "$DEMO/zeroize/service/90-zeroize-display.rules" /etc/udev/rules.d/
$B 'chmod 755 /usr/lib/zeroize/zeroize-stage.sh && chmod 644 /etc/systemd/system/zeroize-stage.service /etc/udev/rules.d/90-zeroize-display.rules && systemctl daemon-reload && udevadm control --reload'
# Galene VM image and the krun runtime: crun + libkrun.so.1 (cross-built in cache/out)
$B 'install -d /usr/local/share/ashen /usr/local/lib/ashen/krun-crun'
[ -f "$ASHEN_OUT/galene-rootfs.tar.gz" ] && "$DEMO/bscp" "$ASHEN_OUT/galene-rootfs.tar.gz" /usr/local/share/ashen/
# upload next to the target and rename: the running VM keeps the old binaries open
"$DEMO/bscp" "$ASHEN_OUT/krun/crun" /usr/local/lib/ashen/krun-crun/crun.new
"$DEMO/bscp" "$ASHEN_OUT/krun/libkrun.so.1" /usr/local/lib/ashen/krun-crun/libkrun.so.1.new
$B 'cd /usr/local/lib/ashen/krun-crun && mv crun.new crun && mv libkrun.so.1.new libkrun.so.1'
echo installed
