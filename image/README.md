# Demo image

> [!IMPORTANT]
> This README file along with the image build scripts are LLM-generated. Enjoy with caution.

`build-image.sh` builds a complete eMMC image from source and pinned inputs, as a qdl flash dir
in `image/flash/` of the build outputs (`cache/out/` by default; see `env.sh`).

## What goes in

| Partition | Content | From |
|---|---|---|
| `hyp_a`, `boot_a` | Patched QHEE + EL2 U-Boot (KVM) | `kvm-hvc-poc` submodule (nix) |
| `hyp_b`, `boot_b`, all other firmware | Arduino stock | `unoq-bootloader-emmc-linux-251020.zip`, hash-pinned |
| `efi` | systemd-boot, demo kernel, initrd, DTB, one boot entry | `kernel/build.sh` |
| `rootfs` | Debian trixie + demo services, wipe payload, krun, Galene guest, MCU firmware | mmdebstrap, `packages`, `customize.sh` |
| `userdata` | Empty ext4 (unused) | |

The Debian packages come from `snapshot.debian.org` at `$SNAPSHOT` (default in `build-image.sh`),
and the filesystem images use fixed UUIDs, hash seeds and timestamps. `manifest` lists every
package version.

## Building

```sh
git submodule update --init --recursive    # all sources except the kernel
ASHEN_LINUX=/path/to/ashen-linux image/build-image.sh   # everything, from source
SKIP_INPUTS=1 image/build-image.sh        # reuse kernel/payload/krun/guest/fw builds
WIFI_PROFILE=~/office.nmconnection ...    # optional Wi-Fi profile (credentials stay out of git)
```

The rootfs stage needs an arm64 Debian host, because this VM can't run arm64 package scripts (no
binfmt_misc). By default that's the demo board itself (`BUILDER=root@host`, work dir
`BUILD_DIR=/home/arduino/ashen-image`, ~6 GB). The build installs `mmdebstrap` there if missing.

## Flashing

1. Put the board in EDL mode (USB `05c6:9008`).
2. From the flash dir, run `qdl --storage emmc prog_firehose_ddr.elf rawprogram0.xml patch0.xml`.
   `rawprogram0.arduino.xml` is Arduino's original table, for reference.

## First boot

- The rootfs grows to fill its partition (`x-systemd.growfs`). SSH host keys and the machine-id
  are generated fresh.
- Root login is by key only: `files/root/.ssh/authorized_keys`.
- The new image has a new host Noise key, so the MCU (still paired with the old host) must be
  erased once. Flash `/usr/local/share/ashen/ashen-fw.elf` with `demo/mcu-flash.sh`, or press the
  tamper button. After that, pairing is trust-on-first-use, and the first boot provisions the
  volume.
- Network: wired via the dock is a bridge `br0` (`files/etc/NetworkManager`); the VM is NATed behind
  the board and Galene is at `https://<board>/`.
  Wi-Fi only if built with `WIFI_PROFILE`.
