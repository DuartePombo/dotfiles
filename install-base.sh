#!/bin/bash
# install-base.sh: install the base Arch system the way helios was installed (see docs/install.md).
# Run it by hand from the Arch live ISO, as root, with a network connection:
#   partition -> LUKS2 -> Btrfs subvolumes -> pacstrap -> system config -> systemd-boot.
# THIS ERASES THE WHOLE TARGET DISK. It asks for the disk and for typed confirmation first.
# Passphrases and passwords are typed at the prompts and never stored.
# After the first boot, clone the dotfiles repo and run setup.sh.

set -euo pipefail

die() { echo "Error: $*" >&2; exit 1; }
ask() { # ask VAR "prompt" [default]
    local reply
    read -rp "$2${3:+ [$3]}: " reply
    printf -v "$1" '%s' "${reply:-${3:-}}"
}

# --- Preconditions -------------------------------------------------------------------------------------------
[[ $EUID -eq 0 ]] || die "run as root (from the Arch live ISO)"
[[ -d /run/archiso ]] || die "this doesn't look like the Arch live ISO (/run/archiso missing)"
[[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode"
findmnt /mnt >/dev/null && die "/mnt is already in use; unmount it first (umount -R /mnt)"
ping -c 1 -W 5 archlinux.org >/dev/null || die "no network (use iwctl for Wi-Fi)"
timedatectl set-ntp true

# --- Choices ---------------------------------------------------------------------------------------------------
disk='' hostname='' username='' keymap='' timezone='' confirm=''   # set by ask
echo "Disks:"
lsblk -dpno NAME,SIZE,MODEL,TRAN | grep -vE '^/dev/(loop|sr|zram)'
echo
ask disk "Target disk to ERASE (full path, e.g. /dev/nvme0n1)"
[[ -b $disk && $(lsblk -dno TYPE "$disk") == disk ]] || die "$disk is not a whole disk"
# Refuse the disk the live system booted from
live_src=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)
[[ -n $live_src && $(lsblk -no PKNAME "$live_src" 2>/dev/null) == "${disk#/dev/}" ]] && die "$disk holds the live ISO"

# Partition names: nvme0n1 -> nvme0n1p1, mmcblk0 -> mmcblk0p1, sda -> sda1
if [[ $disk =~ [0-9]$ ]]; then part="${disk}p"; else part="$disk"; fi
esp="${part}1"
root="${part}2"

ask hostname "Hostname" "helios"
ask username "Username (will be in group wheel)"
[[ $username =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid username"
ask keymap "Console keymap" "us"
ask timezone "Time zone" "Europe/Lisbon"
[[ -e /usr/share/zoneinfo/$timezone ]] || die "unknown time zone $timezone"

echo
echo "About to ERASE $disk and install Arch:"
lsblk -po NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$disk"
echo "  ESP $esp (1 GiB), LUKS2 root $root, hostname $hostname, user $username, keymap $keymap, $timezone"
ask confirm "Type the disk name ($(basename "$disk")) to erase it"
[[ $confirm == "$(basename "$disk")" ]] || die "not confirmed, nothing was changed"

# --- Partition, encrypt, format --------------------------------------------------------------------------------
sgdisk --zap-all "$disk"
sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI "$disk"
sgdisk -n 2:0:0 -t 2:8309 -c 2:cryptroot "$disk"
partprobe "$disk"
udevadm settle

echo "Choose the disk passphrase (you type it at every boot; there's no way back without it):"
cryptsetup luksFormat --type luks2 "$root"
cryptsetup open --allow-discards --persistent "$root" cryptroot

mkfs.fat -F 32 -n EFI "$esp"
mkfs.btrfs -L arch /dev/mapper/cryptroot

mount /dev/mapper/cryptroot /mnt
# @docker and @containerd keep Docker's images and containers out of snapper snapshots
for s in @ @home @snapshots @var_log @pkg @docker @containerd; do btrfs subvolume create "/mnt/$s"; done
umount /mnt

o=noatime,compress=zstd
mount -o "$o,subvol=@" /dev/mapper/cryptroot /mnt
mount --mkdir -o "$o,subvol=@home" /dev/mapper/cryptroot /mnt/home
mount --mkdir -o "$o,subvol=@snapshots" /dev/mapper/cryptroot /mnt/.snapshots
mount --mkdir -o "$o,subvol=@var_log" /dev/mapper/cryptroot /mnt/var/log
mount --mkdir -o "$o,subvol=@pkg" /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount --mkdir -o "$o,subvol=@docker" /dev/mapper/cryptroot /mnt/var/lib/docker
mount --mkdir -o "$o,subvol=@containerd" /dev/mapper/cryptroot /mnt/var/lib/containerd
mount --mkdir -o fmask=0077,dmask=0077 "$esp" /mnt/boot

# --- Base system -----------------------------------------------------------------------------------------------
pacstrap -K /mnt base linux linux-lts linux-firmware intel-ucode btrfs-progs networkmanager sudo neovim git \
    github-cli base-devel man-db zram-generator sof-firmware
genfstab -U /mnt >> /mnt/etc/fstab
sed -i 's/subvolid=[0-9]*,//g' /mnt/etc/fstab   # mount subvolumes by name, so restored snapshots still mount

# --- Configure, inside the new system --------------------------------------------------------------------------
in_chroot() { arch-chroot /mnt "$@"; }

in_chroot ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
in_chroot hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
in_chroot locale-gen
echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf
echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf
echo "$hostname" > /mnt/etc/hostname

echo "Password for root:"
in_chroot passwd
in_chroot useradd -m -G wheel "$username"
echo "Password for $username:"
in_chroot passwd "$username"
echo '%wheel ALL=(ALL:ALL) ALL' > /mnt/etc/sudoers.d/wheel
chmod 440 /mnt/etc/sudoers.d/wheel
in_chroot visudo -cf /etc/sudoers.d/wheel

# systemd-based initramfs with LUKS unlock (setup.sh later adds helios's drop-in in /etc/mkinitcpio.conf.d/)
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' \
    /mnt/etc/mkinitcpio.conf
in_chroot mkinitcpio -P

# systemd-boot: files from inside the chroot; the EFI boot entry is registered from outside (below)
in_chroot bootctl install || true
cat > /mnt/boot/loader/loader.conf <<'EOF'
default arch.conf
timeout 3
console-mode max
EOF
uuid=$(blkid -s UUID -o value "$root")
opts="rd.luks.name=$uuid=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw zswap.enabled=0"
cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options $opts
EOF
cat > /mnt/boot/loader/entries/arch-lts.conf <<EOF
title   Arch Linux (LTS fallback)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options $opts
EOF

cat > /mnt/etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
EOF

in_chroot systemctl enable systemd-boot-update.service NetworkManager systemd-timesyncd

# Outside the chroot, so the "Linux Boot Manager" EFI entry gets registered
bootctl --esp-path=/mnt/boot install

umount -R /mnt
echo
echo "Base install done. Remove the USB stick and reboot. After the first boot:"
echo "  nmcli device wifi connect \"<SSID>\" --ask"
echo "  git clone https://github.com/DuartePombo/dotfiles.git ~/dotfiles && ~/dotfiles/setup.sh"
