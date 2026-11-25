
<p align="center">
    <img alt="ashen logo showing a stylized flame in a red circle" width="100px" src="ashen-logo-color-no-transparency.png">
</p>

# Ashen demo on the Arduino UNO Q

This demo runs the [Galene videoconference server](https://galene.org/) on an arduino uno Q inside of a microVM-based
container using [crun](https://github.com/containers/crun) through [podman](https://podman.io/). The container's memory
is tagged using ashen's kernel interface to mark it for early wiping on a tamper alarm. The VM's storage volume is
encrypted using LUKS with a key stored in the fTPM embedded in `ashen-firmware`.

The demo firmware configures pin D10 (PB9) of the arduino as a tamper input. When this pin is pulled down, the firmware
alerts the host, erases the TPM keys, and tears down its encrypted heartbeat link. The host then proceeds to wipe its
memory, prioritizing the memory areas used by the Galene VM.

After the wipe, the board performs a normal reboot. During the reboot, the setup will detect that the system is
currently unkeyed and reset the demo with fresh keys. 

## Setup

* The demo consists of an arduino uno Q with a hand-made shield that is hooked up to a small screen through a USB dock,
  and to a big red button through a long cable.
* The demo arduino is connected to a hand-made shield. This shield has a Type C PD decoy that produces 9V from a
  type C laptop power supply. The 9V are routed to the arduino's VIN and to the button's LEDs on the button connector.
  The shield connects the button's contact from the button connector to the arduino's tamper input pin. with a pullup.
* The board can be hooked up to a network using either gigabit ethernet or its on-board wifi. By default, it listens for
  DHCPv4 on the USB dock's GbE interface. Galene will be served on the default https port 443.

## Repositories

You have to check out ashen-linux yourself and provide its path to the build scripts. The other repos are added to this
repo as git submodules. Use `git submodule update --init --recursive` to clone them.

| Path | Repository |
|---|---|
| `zeroize/` | https://github.com/yasec-de/ashen-kexec-zeroizer (wipe payload) |
| `ashen-fw/` | https://github.com/yasec-de/ashen-fw (wolfTPM submodule: ashen-wolfTPM) |
| `libkrun/` | https://github.com/yasec-de/ashen-libkrun, branch `stable-1.19.x-crash-memaction` |
| `crun/` | https://github.com/yasec-de/ashen-crun, branch `main` |
| `linux-demo/` | https://github.com/yasec-de/ashen-linux, branch `ashen-demo` |

> [!NOTE]
> This repo is mostly LLM-generated code with a moderate amount of supervision. For this reason, proceed with caution
> when reading this code and of course don't use it in places where it would hurt if it didn't work right.

## Tools (run from this directory)

The repo includes some debugging tools. They're all LLM-created, so proceed with caution.

| Script | Does |
|---|---|
| `bssh` | SSH to the board (wired, Wi-Fi fallback) |
| `kernel/build.sh`, `kernel/deploy.sh [--reboot]` | Build the demo kernel and DTB, install them as default boot entry |
| `vm/build-guest.sh`, `vm/build-krun.sh`, `vm/build-crun.sh` | Galene guest rootfs tarball; libkrun.so.1; crun |
| `build-payload.sh`, `fw-build.sh`, `mcu-flash.sh` | Wipe payload; MCU firmware |
| `install-rootfs.sh` | Install units, scripts, guest tarball, payload and krun on the board |
| `image/build-image.sh` | Full reproducible board image (see image/README.md) |
| `cycle-test.sh reboot\|tamper` | One reboot/tamper cycle with timings and TLS fingerprints |
| `grab-frame.sh`, `uart-log.py`, `board-reset.sh` | HDMI capture, UART log, hard reset |

## Limitations

- Power cycles reset not only the Linux SoC, but also the MCU running ashen-firmware. This means power cycling always
  deletes the keys like a tamper alarm would and reset the demo.
- `/dev/tpmrm0` can't swap object contexts, so we use `/dev/tpm0` directly.

