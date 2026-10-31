# Installing Arch on helios

How the base system on helios was installed: from the Arch ISO to a first boot with Wi-Fi and SSH.
Everything after that (packages, configs, desktop) comes from this repo.

> **Warning:** steps 2–4 erase the whole target disk, including any other operating system on it.
> Back up anything you want to keep, and check the disk name with `lsblk` before every destructive command.

The commands use this machine's disk, `/dev/nvme0n1`. If your target disk has another name, replace it
everywhere. NVMe partitions get a `p` before the number (`nvme0n1p1`); SATA and USB disks don't (`sda1`).
Text in angle brackets, like `<user>` or `<SSID>`, is a placeholder: replace it, brackets included.

## Before you start
- Arch ISO on a USB stick (used: ISO 2026.10.01 on a Ventoy stick).
- Firmware settings: UEFI boot, Secure Boot off, SATA mode AHCI. On this Acer, the Secure Boot setting can only
  be changed after a supervisor password is set.
- Passwords and the disk passphrase are typed when asked. Don't write them into scripts or notes.

## 1. Live environment
Boot the stick in UEFI mode, then:
```
iwctl                      # station wlan0 scan / get-networks / connect "<SSID>"
ping -c 3 archlinux.org
timedatectl                # check "System clock synchronized: yes"
lsblk                      # find the target disk: here nvme0n1 (953.9G); the stick was sda
```
Optional: to paste commands from another computer, set a root password for the live system with `passwd`,
then connect with `ssh root@<ip>`.

## 2. Partition
> **This destroys everything on the disk.** Confirm with `lsblk` that `/dev/nvme0n1` is the disk you mean.
```
sgdisk --zap-all /dev/nvme0n1
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI /dev/nvme0n1
sgdisk -n 2:0:0 -t 2:8309 -c 2:cryptroot /dev/nvme0n1
```
This creates a 1 GiB EFI system partition and a second partition, filling the rest of the disk, for the
encrypted root.

## 3. Encrypt
```
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open --allow-discards --persistent /dev/nvme0n1p2 cryptroot
```
`luksFormat` asks you to type `YES`, then a passphrase. Without the passphrase the data can't be recovered.
`--allow-discards --persistent` lets TRIM reach the SSD through the encryption and saves that setting in the
LUKS header, so it doesn't have to be repeated at every boot.

## 4. Filesystems and subvolumes
```
mkfs.fat -F 32 -n EFI /dev/nvme0n1p1
mkfs.btrfs -L arch /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
for s in @ @home @snapshots @var_log @pkg; do btrfs subvolume create /mnt/$s; done
umount /mnt

o=noatime,compress=zstd
mount -o $o,subvol=@ /dev/mapper/cryptroot /mnt
mount --mkdir -o $o,subvol=@home /dev/mapper/cryptroot /mnt/home
mount --mkdir -o $o,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount --mkdir -o $o,subvol=@var_log /dev/mapper/cryptroot /mnt/var/log
mount --mkdir -o $o,subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount --mkdir -o fmask=0077,dmask=0077 /dev/nvme0n1p1 /mnt/boot
```

| Subvolume    | Mounted at               | Why it's separate                                     |
|--------------|--------------------------|-------------------------------------------------------|
| `@`          | `/`                      | the system; this is what snapshots roll back          |
| `@home`      | `/home`                  | a system rollback doesn't touch your files            |
| `@snapshots` | `/.snapshots`            | snapshots of `/` are kept here                        |
| `@var_log`   | `/var/log`               | logs survive a rollback                               |
| `@pkg`       | `/var/cache/pacman/pkg`  | the package cache stays out of snapshots              |

The ESP is mounted at `/boot`, so kernels live outside Btrfs and outside snapshots. `fmask/dmask=0077` makes it
readable by root only.

## 5. Base system
```
pacstrap -K /mnt base linux linux-lts linux-firmware intel-ucode btrfs-progs networkmanager sudo neovim git github-cli base-devel man-db zram-generator sof-firmware
genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's/subvolid=[0-9]*,//g' /mnt/etc/fstab
```
The `sed` removes `subvolid=` from fstab, so subvolumes are mounted by name only. That keeps fstab valid after
a snapshot is restored, which gives the subvolume a new ID.

## 6. Configure the system (inside the chroot)
```
arch-chroot /mnt
```
Time, locale, keyboard, hostname:
```
ln -sf /usr/share/zoneinfo/Europe/Lisbon /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
echo helios > /etc/hostname
```
Users and sudo:
```
passwd                                   # root password
useradd -m -G wheel <user>
passwd <user>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
```
Initramfs. The `systemd` and `sd-encrypt` hooks unlock the disk at boot; `sd-vconsole` and `keyboard` come
before them so the passphrase prompt uses the right keymap:
```
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
```
Bootloader (systemd-boot). In the chroot, `bootctl` copies its files but can't register the EFI boot entry;
step 7 does that.
```
bootctl install

cat > /boot/loader/loader.conf <<'EOF'
default arch.conf
timeout 3
console-mode max
EOF
```
Boot entries, one for the normal kernel and one for the LTS kernel as a fallback. `blkid` looks up the UUID of
the encrypted partition (note the unquoted `EOF`, so `$UUID` gets filled in):
```
UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options rd.luks.name=$UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw zswap.enabled=0
EOF

cat > /boot/loader/entries/arch-lts.conf <<EOF
title   Arch Linux (LTS fallback)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options rd.luks.name=$UUID=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw zswap.enabled=0
EOF
```
The CPU microcode is built into the initramfs by the `microcode` hook, so the entries don't need a separate
`initrd` line for it.

Swap in compressed RAM (zram). zswap is turned off with `zswap.enabled=0` above, since it would sit in front
of zram:
```
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF
```
Services, then leave the chroot:
```
systemctl enable systemd-boot-update.service NetworkManager systemd-timesyncd
exit
```
> Type `exit` on its own. Commands pasted after `exit` in the same block are lost.

## 7. Register the boot entry and reboot
Back in the live system, outside the chroot:
```
bootctl --esp-path=/mnt/boot install
umount -R /mnt
reboot
```
Remove the USB stick when the machine restarts.

## 8. First boot
Unlock the disk with the passphrase and log in as `<user>`.

Check that the firmware has a "Linux Boot Manager" entry. If it's missing, the machine only booted through the
fallback `EFI/BOOT/BOOTX64.EFI`; `sudo bootctl install` adds the entry.
```
efibootmgr
```
Network, SSH and `helios.local` name resolution:
```
nmcli device wifi connect "<SSID>" --ask
sudo pacman -S openssh avahi
sudo systemctl enable --now sshd avahi-daemon
```
From each computer you want to log in from, copy your SSH key: `ssh-copy-id <user>@helios.local`.

Claude Code (native installer, puts itself in `~/.local/bin`). The PATH line is only needed until the
`.bashrc` from this repo is in place:
```
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

## 9. Next
Clone this repo to `~/dotfiles`; the rest of the setup is done from there.
```
git clone https://github.com/DuartePombo/dotfiles.git ~/dotfiles
```
