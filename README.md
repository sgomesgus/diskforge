# Diskforge

![Linux](https://img.shields.io/badge/OS-Linux-blue) ![Bash](https://img.shields.io/badge/Language-Bash-green) ![Automation](https://img.shields.io/badge/Type-Automation-orange) ![Storage](https://img.shields.io/badge/Module-Disk%20Management-red)

> **Important Note:** This script performs destructive operations on storage devices. Always double-check the selected disk and test in non-critical environments before use.

---

## Purpose

This Bash script automates the full lifecycle of disk provisioning on Linux systems. It is designed to safely wipe, partition, format, mount, and persist storage devices with minimal manual intervention.

Ideal for personal setups, lab environments, and rapid workstation provisioning.

---

## How It Works

For a selected disk, the script executes a structured setup workflow:

1. **Safety Validation:** Ensures the script is not executed as root and prevents targeting the system disk.
2. **Disk Selection:** Displays available devices and allows manual selection.
3. **Full Wipe:** Removes all filesystem signatures from the disk.
4. **Partitioning:** Creates a new GPT partition table and a primary partition spanning the entire disk.
5. **Filesystem Creation:** Formats the partition as EXT4 or NTFS.
6. **Mount Point Creation:** Generates a user-level mount directory.
7. **Temporary Mount:** Mounts the partition and applies correct ownership.
8. **Persistent Configuration:** Retrieves the UUID and safely appends it to `/etc/fstab`.
9. **Validation:** Reloads systemd and verifies automatic mounting.

---

## Key Safety Practices

* **Root Execution Block:** Prevents direct execution as root to reduce risk of accidental misuse.
* **System Disk Protection:** Detects and blocks operations on the currently mounted root disk.
* **Double Confirmation:** Requires explicit user confirmation before destructive actions.
* **UUID-Based Mounting:** Ensures stable and reliable mounting across reboots.
* **fstab Backup:** Automatically creates a backup before modifying system configuration.
* **Kernel Sync Handling:** Uses `udevadm settle` and `partprobe` to avoid race conditions.

---

## Configuration Options

The script dynamically adjusts behavior based on user input:

    Filesystem Options:
    1) EXT4 (native Linux performance)
    2) NTFS (cross-platform compatibility)

    Mount Location:
    ~/[UserDefinedName]

    Mount Options:
    - EXT4: defaults
    - NTFS: defaults,uid=<user>,gid=<group>

---

## Requirements & Usage

| Category | Details |
| :--- | :--- |
| **OS** | Linux |
| **Tools** | `lsblk`, `parted`, `wipefs`, `blkid`, `mount`, `udevadm` |
| **Filesystem Tools** | `mkfs.ext4`, `mkfs.ntfs` |
| **Permissions** | User-level execution with `sudo` privileges |
| **Execution** | Run manually in terminal |

---

## Usage

    chmod +x setup-hd.sh
    ./setup-hd.sh

---

## Example Workflow

    Disco (ex: sda ou nvme0n1): sdb
    Sistema de arquivos: EXT4
    Nome: Files

Result:

    /home/user/Files

Mounted automatically at boot via `/etc/fstab`.

---

## Warnings

* **ALL DATA ON THE SELECTED DISK WILL BE PERMANENTLY ERASED**
* Always verify the disk identifier (`sda`, `sdb`, `nvme0n1`, etc.)
* Do not use on production systems without prior validation
