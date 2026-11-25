#!/bin/bash
# Reboot the board one way or another and report how the demo came back.
#   cycle-test.sh reboot|tamper
# Prints time until SSH and until Galene answers, the narration, and the TLS fingerprint.
set -u
DEMO=$(cd "$(dirname "$0")" && pwd)
B=$DEMO/bssh
H=$($B --host)
GALENE=${GALENE:-192.168.1.17}
fp() { timeout 20 $B "echo | timeout 5 openssl s_client -connect $GALENE:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 | cut -d= -f2"; }
before=$(fp 2>/dev/null)
$B 'cat /proc/sys/kernel/random/boot_id > /var/tmp/boot_id.before; sync'
case "$1" in
reboot) $B 'systemctl reboot' ;;
tamper) "$DEMO/bscp" "$DEMO/press-button.py" /var/tmp/
	$B 'python3 /var/tmp/press-button.py' ;;
esac
t0=$(date +%s); sleep 8
until timeout 2 bash -c "exec 3<>/dev/tcp/$H/22" 2>/dev/null; do sleep 1; done
echo "ssh after $(( $(date +%s) - t0 ))s"
until timeout 15 $B "timeout 5 curl -sk -o /dev/null https://$GALENE/" 2>/dev/null; do
	sleep 1; [ $(( $(date +%s) - t0 )) -gt 300 ] && { echo "Galene not up after 300s"; break; }
done
echo "galene after $(( $(date +%s) - t0 ))s"
timeout 30 $B 'echo "boot_id $(cat /var/tmp/boot_id.before) -> $(cat /proc/sys/kernel/random/boot_id)"
dmesg | grep -E "ashen:|galene-vm:|fw:|zeroize" | cut -c16-160
echo "armed=$(cat /sys/bus/serial/devices/serial0-0/armed)"; systemd-analyze | head -1'
after=$(fp)
echo "fingerprint before: $before"
echo "fingerprint after:  $after"
