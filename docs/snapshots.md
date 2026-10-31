# Snapshots on helios

The root filesystem (`/`, the Btrfs subvolume `@`) is snapshotted with snapper. Snapshots are taken:
- before and after every pacman run (snap-pac): a **pre** and a **post** snapshot,
- every hour (timeline),
- whenever you create one by hand.

Old ones are deleted automatically: snap-pac snapshots after about 10 pacman runs, timeline snapshots after
5 hours (hourly) or 7 days (daily). Snapshots you create by hand are kept until you delete them.

**Not** in the snapshots, so a rollback never touches them:

| What                        | Where                    | Why                                              |
|-----------------------------|--------------------------|--------------------------------------------------|
| Your files                  | `/home` (`@home`)        | separate subvolume; back it up separately        |
| Logs                        | `/var/log` (`@var_log`)  | so you can read what went wrong after a rollback |
| Downloaded packages         | `/var/cache/pacman/pkg` (`@pkg`) | needed to reinstall older versions       |
| Kernels and initramfs       | `/boot` (EFI partition)  | not Btrfs; see the kernel notes below            |

Listing, comparing and creating snapshots works without `sudo`. Undoing changes needs `sudo`.

## List snapshots
```
snapper list
```
- `#`: the snapshot number. `0` is always the current, live system.
- `Type`: `single` (timeline or by hand), or `pre`/`post` for the two halves of a pacman run. `Pre #` on a
  post snapshot points to its pre snapshot.
- `Description`: for pacman runs, the command (pre) and the packages (post).

To see what pacman actually changed and when, the log lives outside the snapshots:
```
grep -E '\[ALPM\] (upgraded|installed|removed|downgraded)' /var/log/pacman.log | tail -30
```

## Compare snapshots
Which files changed between two snapshots, for example the pre/post pair 12 and 13:
```
snapper status 12..13
```
Each line starts with flags: `+` created, `-` deleted, `c` content changed, `p` permissions, `u` owner, `g`
group. Use `0` for the live system: `snapper status 12..0` shows everything that changed since snapshot 12.

The actual changes in one file:
```
snapper diff 12..13 /etc/pacman.conf
```
Every snapshot is also a normal, read-only directory tree you can browse:
```
ls /.snapshots/12/snapshot/etc/
```
To get a single file back, copy it out:
```
sudo cp -a /.snapshots/12/snapshot/etc/some.conf /etc/some.conf
```

## Create a snapshot by hand
Before trying something risky:
```
snapper create -d "before trying X"
```
Delete it when you don't need it anymore: `snapper delete <number>`.

## Undo a package update
### Option 1: reinstall the previous version from the cache
Best for one or a few packages, and the right way for kernels. pacman keeps the packages it downloaded in
`/var/cache/pacman/pkg`, so the old version is usually still there:
```
ls /var/cache/pacman/pkg/ | grep '^<package>-'
sudo pacman -U /var/cache/pacman/pkg/<package>-<old version>-x86_64.pkg.tar.zst
```
This runs like any pacman command (with its own pre/post snapshots). Until the problem is fixed upstream, skip
the package when upgrading: `sudo pacman -Syu --ignore <package>`.

For a kernel, downgrade the kernel and its headers together (the NVIDIA module is built against the headers):
`linux` + `linux-headers`, or `linux-lts` + `linux-lts-headers`. Then reboot.

Don't empty the package cache (`pacman -Scc`): this option depends on it.

### Option 2: undo a whole pacman run with snapper
Find the run's pre/post pair with `snapper list` (say 12 and 13), check what it changed, take a snapshot of
the current state in case you want it back, then undo:
```
snapper status 12..13 | less
snapper create -d "before undoing 12..13"
sudo snapper undochange 12..13
```
Every file that changed between 12 and 13 is put back the way it was in 12, including pacman's own database,
so pacman stays in sync with what's on disk. Reboot afterwards: running programs still use the files they
loaded.

Be careful with this option:
- If the pacman run updated a kernel, don't use it: `/boot` isn't in the snapshots, so the kernel there would
  stay new while its modules go back to old. Use option 1 instead.
- If you edited one of those files after snapshot 13, your edit is undone too.

## Roll back `/` completely
`/` is the subvolume `@`. A rollback renames the current `@` (to keep it, just in case) and creates a new,
writable `@` from a snapshot. The boot entries and `/etc/fstab` mount the subvolume by its name, `@`, so the
next boot uses the restored one. (snapper's own `snapper rollback` command is meant for a different layout and
doesn't change what boots here; don't use it.)

### First, check the kernel
```
ls /usr/lib/modules                           # kernels on the system now
ls /.snapshots/<N>/snapshot/usr/lib/modules   # kernels in snapshot N
```
If both show the same versions, nothing special is needed. If they differ, a kernel update happened after
snapshot N, and `/boot` will keep the newer kernel. After the rollback, follow
[Fix the kernel after a rollback](#fix-the-kernel-after-a-rollback).

### From the running system
```
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt    # the top level of the Btrfs filesystem
ls /mnt                                                 # @  @home  @pkg  @snapshots  @var_log
sudo mv /mnt/@ /mnt/@broken                             # keep the current root under another name
sudo btrfs subvolume snapshot /mnt/@snapshots/<N>/snapshot /mnt/@
sudo umount /mnt
reboot
```
Renaming the running root is fine: the system keeps running from `@broken` until you reboot. Reboot right
away; anything you change before that ends up in `@broken`. After the reboot, `findmnt /` should show
`subvol=/@`. Snapshot N itself is unchanged and stays in the list.

### From the Arch USB stick (if helios won't boot)
First try the other kernel: pick **Arch Linux (LTS fallback)** in the boot menu. If that also fails, boot the
Arch USB stick in UEFI mode. Check with `lsblk` that the encrypted partition is `nvme0n1p2`.

> These commands only rename and create subvolumes. Never run `mkfs`, `cryptsetup luksFormat` or `sgdisk` here:
> they would erase the disk.

```
cryptsetup open /dev/nvme0n1p2 cryptroot           # asks for the disk passphrase
mount -o subvolid=5 /dev/mapper/cryptroot /mnt
grep -H -E '<(date|description)>' /mnt/@snapshots/*/info.xml    # to pick a snapshot number
ls /mnt/@/usr/lib/modules /mnt/@snapshots/<N>/snapshot/usr/lib/modules   # the kernel check
mv /mnt/@ /mnt/@broken
btrfs subvolume snapshot /mnt/@snapshots/<N>/snapshot /mnt/@
umount /mnt
reboot
```
If the kernel versions differed, do the next section before rebooting.

### Fix the kernel after a rollback
The restored system expects older kernels than the ones in `/boot`. Reinstalling those older kernel packages
from the cache puts the matching kernel and initramfs back in `/boot`.

If only one of the two kernels changed, the simplest way is to boot the other one from the boot menu and run
the `pacman -U` line below with `sudo`. Otherwise, from the Arch USB stick:
```
cryptsetup open /dev/nvme0n1p2 cryptroot           # skip if it's still open
mount -o subvol=@ /dev/mapper/cryptroot /mnt
mount -o subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
pacman -Q linux linux-lts                          # the versions this system expects, e.g. "linux 7.2.11.arch1-1"
SNAP_PAC_SKIP=y pacman -U /var/cache/pacman/pkg/linux-<version>-x86_64.pkg.tar.zst
exit
umount -R /mnt
reboot
```
Do the same for `linux-lts` if its version changed too. `SNAP_PAC_SKIP=y` turns off the automatic snapshots,
which can't be taken from the USB stick and would otherwise stop pacman.

### Clean up `@broken`
Once you're sure the restored system is fine:
```
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt
sudo btrfs subvolume list -o /mnt/@broken          # subvolumes nested inside it
sudo btrfs subvolume delete /mnt/@broken/var/lib/portables /mnt/@broken/var/lib/machines
sudo btrfs subvolume delete /mnt/@broken
sudo umount /mnt
```
systemd created two empty subvolumes inside the original `@` (`var/lib/portables` and `var/lib/machines`).
A subvolume can't be deleted while it still contains others, so delete whatever the `list -o` line shows
first. If it shows nothing, skip that line.
