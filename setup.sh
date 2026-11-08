#!/bin/bash
# setup.sh: turn a fresh base install (install-base.sh) into the full helios setup, or bring an existing one in
# line with this repo. Run as your user (not root) from anywhere; it uses sudo when needed. Safe to run again:
# every step checks first and only changes what's missing or different.
#
# Steps: Docker subvolumes -> packages (pacman, AUR via paru) -> snapper -> /etc files -> stow -> services
#        -> initramfs (only if its config changed) -> user tools (mise, Miniforge + conda envs, VS Code
#        extensions, Neovim plugins).
# Machine-specific files come from hosts/$(uname -n)/ when that folder exists.

set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
host=$(uname -n)
hostdir="$repo/hosts/$host"
[[ -d $hostdir ]] || hostdir=""
me=$(id -un)

miniforge_version=26.9.4-1                  # pinned: bump deliberately
miniforge_dir="$HOME/miniforge3"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }
die()  { echo "Error: $*" >&2; exit 1; }

[[ $EUID -ne 0 ]] || die "run as your user, not root"
sudo -v || die "sudo is needed"

echo "setup.sh for host '$host' (host files: ${hostdir:-none}), user '$me', repo $repo"
read -rp "Continue? [y/N] " reply
[[ $reply == [yY]* ]] || exit 0

snapshot() { # take a snapper snapshot if snapper is set up
    if [[ -f /etc/snapper/configs/root ]]; then
        sudo snapper -c root create -d "setup.sh: $1" >/dev/null && note "snapshot taken: $1"
    fi
}

# --- 1. Docker subvolumes (before Docker can ever run) ---------------------------------------------------------
say "Btrfs subvolumes for Docker"
root_uuid=$(findmnt -no UUID /)
opts=$(findmnt -no OPTIONS / | sed -E 's/(^|,)(subvolid|subvol)=[^,]*//g; s/^,//')
need_fstab=()
for pair in "@docker:/var/lib/docker" "@containerd:/var/lib/containerd"; do
    mp=${pair#*:}
    grep -qE "[[:space:]]${mp}[[:space:]]" /etc/fstab || need_fstab+=("$pair")
done
if (( ${#need_fstab[@]} )); then
    if [[ -n $(ls -A /var/lib/docker /var/lib/containerd 2>/dev/null) ]]; then
        die "/var/lib/docker or /var/lib/containerd already has data; move it into the subvolumes by hand first"
    fi
    snapshot "before Docker subvolume fstab entries"
    top=$(mktemp -d)
    sudo mount -o subvolid=5 /dev/mapper/cryptroot "$top"
    for pair in "${need_fstab[@]}"; do
        sv=${pair%%:*}
        mp=${pair#*:}
        [[ -d $top/$sv ]] || sudo btrfs subvolume create "$top/$sv"
        sudo mkdir -p "$mp"
        printf '\n# /dev/mapper/cryptroot LABEL=arch (%s, outside snapper snapshots)\nUUID=%s\t%s\tbtrfs\t%s,subvol=/%s\t0 0\n' \
            "$sv" "$root_uuid" "$mp" "$opts" "$sv" | sudo tee -a /etc/fstab >/dev/null
        note "added $sv at $mp to /etc/fstab"
    done
    sudo umount "$top"
    rmdir "$top"
    sudo findmnt --verify
    sudo systemctl daemon-reload
fi
for mp in /var/lib/docker /var/lib/containerd; do
    findmnt "$mp" >/dev/null || sudo mount "$mp"
done
note "ok"

# --- 2. Packages -----------------------------------------------------------------------------------------------
say "Package repositories"
# Steam and its 32-bit graphics drivers come from multilib, so it must be enabled before the lists are installed
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]$/{s/^#//;n;s/^#//}' /etc/pacman.conf
    note "enabled the multilib repository"
fi

say "Packages (pacman)"
lists=("$repo/packages/pacman.txt")
[[ -n $hostdir && -f $hostdir/pacman.txt ]] && lists+=("$hostdir/pacman.txt")
cat "${lists[@]}" | sudo pacman -Syu --needed -

say "AUR helper (paru)"
if ! command -v paru >/dev/null; then
    build=$(mktemp -d)
    git clone https://aur.archlinux.org/paru-bin.git "$build/paru-bin"
    note "review the PKGBUILD before it's built:"
    less "$build/paru-bin/PKGBUILD"
    (cd "$build/paru-bin" && makepkg -si)
    rm -rf "$build"
fi

say "Packages (AUR)"
mapfile -t aur < <(grep -vxE 'paru-bin|[[:space:]]*' "$repo/packages/aur.txt" || true)
# paru shows each new or changed PKGBUILD for review before building
if (( ${#aur[@]} )); then
    paru -S --needed "${aur[@]}"
fi

# --- 3. Snapper (its config must not exist before create-config) ----------------------------------------------
say "Snapper"
if [[ ! -f /etc/snapper/configs/root ]]; then
    # snapper create-config makes its own .snapshots subvolume inside @; replace it with the @snapshots mount
    sudo umount /.snapshots
    sudo rmdir /.snapshots
    sudo snapper -c root create-config /
    sudo btrfs subvolume delete /.snapshots
    sudo mkdir /.snapshots
    sudo mount /.snapshots
    sudo chmod 750 /.snapshots
    note "created config 'root' using the existing @snapshots subvolume"
fi

# --- 4. /etc files ---------------------------------------------------------------------------------------------
say "System files (/etc)"
changed_initramfs=0
changed_udev=0
install_etc() { # install_etc <tree containing etc/>
    local src=$1 f rel dest mode
    [[ -d $src/etc ]] || return 0
    while IFS= read -r -d '' f; do
        rel=${f#"$src"/}
        dest=/$rel
        mode=644
        [[ $rel == etc/snapper/configs/* ]] && mode=640
        if ! sudo cmp -s "$f" "$dest"; then
            sudo install -Dm"$mode" "$f" "$dest"
            note "updated $dest"
            [[ $rel == etc/mkinitcpio.conf.d/* || $rel == etc/modprobe.d/* ]] && changed_initramfs=1
            [[ $rel == etc/udev/* ]] && changed_udev=1
        fi
    done < <(find "$src/etc" -type f -print0)
}
install_etc "$repo/system"
[[ -n $hostdir ]] && install_etc "$hostdir"
(( changed_udev )) && sudo udevadm control --reload
# Let snapper apply the group ACL on /.snapshots (from ALLOW_GROUPS/SYNC_ACL in its config)
sudo snapper -c root set-config ALLOW_GROUPS=wheel SYNC_ACL=yes

# --- 5. Dotfiles (stow) ----------------------------------------------------------------------------------------
say "Dotfiles (stow)"
stow_pkg() { # stow_pkg <stow dir> <package>
    local dir=$1 pkg=$2 f target
    # Move real files that would block stow aside (e.g. the default ~/.bashrc) as <name>.pre-stow.
    # Skip anything that already resolves into the repo (a folder stow linked earlier): that IS the repo file.
    while IFS= read -r -d '' f; do
        target="$HOME/${f#"$dir/$pkg"/}"
        [[ $(realpath -m "$target") == "$dir/$pkg/"* ]] && continue
        if [[ -f $target && ! -L $target ]]; then
            mv -n "$target" "$target.pre-stow"
            note "moved $target to $target.pre-stow"
        fi
    done < <(find "$dir/$pkg" -type f -print0)
    stow -R -d "$dir" -t "$HOME" "$pkg"
}
# Real folders first: otherwise stow would link a missing ~/.local or ~/.config as a whole into the repo,
# and everything apps write there (plugins, caches, runtimes) would end up in the repo.
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.local/state"
stow_pkg "$repo" home
[[ -n $hostdir && -d $hostdir/home ]] && stow_pkg "$hostdir" home
note "ok"

# --- 6. Services and groups ------------------------------------------------------------------------------------
say "Services"
services=(NetworkManager systemd-timesyncd systemd-boot-update sshd avahi-daemon bluetooth power-profiles-daemon
          docker.socket snapper-timeline.timer snapper-cleanup.timer)
pacman -Q nvidia-utils >/dev/null 2>&1 && services+=(nvidia-persistenced)
pacman -Q mullvad-vpn-bin >/dev/null 2>&1 && services+=(mullvad-daemon)
for s in "${services[@]}"; do
    systemctl is-enabled --quiet "$s" 2>/dev/null || { sudo systemctl enable --now "$s"; note "enabled $s"; }
done
# PipeWire, WirePlumber and gnome-keyring are enabled for every user by their packages.

say "Groups"
if ! id -nG "$me" | tr ' ' '\n' | grep -qx docker; then
    sudo usermod -aG docker "$me"
    note "added $me to docker (takes effect at next login)"
fi

# --- 7. Initramfs ----------------------------------------------------------------------------------------------
if (( changed_initramfs )); then
    say "Initramfs (its config changed)"
    snapshot "before mkinitcpio -P"
    sudo mkinitcpio -P
fi

# --- 8. User tools ---------------------------------------------------------------------------------------------
say "mise (Node and other runtimes)"
mise install

say "Miniforge (conda)"
if [[ ! -x $miniforge_dir/bin/conda ]]; then
    dl=$(mktemp -d)
    f="Miniforge3-$miniforge_version-Linux-x86_64.sh"
    url="https://github.com/conda-forge/miniforge/releases/download/$miniforge_version"
    curl -fsSL -o "$dl/$f" "$url/$f"
    curl -fsSL -o "$dl/$f.sha256" "$url/$f.sha256"
    (cd "$dl" && sha256sum -c "$f.sha256") || die "Miniforge checksum mismatch"
    bash "$dl/$f" -b -p "$miniforge_dir"   # batch mode: doesn't touch ~/.bashrc (it sources conda.sh itself)
    rm -rf "$dl"
fi
conda="$miniforge_dir/bin/conda"   # the binary, not the shell function: conda.sh isn't safe under set -u
for env_file in "$repo"/packages/conda/*.yml; do
    name=$(sed -n 's/^name: *//p' "$env_file")
    if "$conda" env list | awk '{print $1}' | grep -qx "$name"; then
        "$conda" env update -n "$name" -f "$env_file" --prune
    else
        "$conda" env create -y -f "$env_file"
    fi
done

say "VS Code extensions"
if command -v code >/dev/null; then
    installed=$(env -u VSCODE_IPC_HOOK_CLI code --list-extensions)
    while read -r ext; do
        [[ -z $ext ]] && continue
        grep -qix "$ext" <<<"$installed" || env -u VSCODE_IPC_HOOK_CLI code --install-extension "$ext"
    done < "$repo/packages/vscode-extensions.txt"
fi

say "Wallpapers (curated list: packages/wallpapers.txt)"
wall_dir="$HOME/Pictures/wallpapers"
mapfile -t walls < <(grep -vE '^(#|[[:space:]]*$)' "$repo/packages/wallpapers.txt")
missing=()
for w in "${walls[@]}"; do [[ -f $wall_dir/$w ]] || missing+=("$w"); done
if (( ${#missing[@]} )); then
    clone=$(mktemp -d)
    git clone --depth 1 https://github.com/D3Ext/aesthetic-wallpapers.git "$clone/repo"
    mkdir -p "$wall_dir"
    for w in "${missing[@]}"; do install -m644 "$clone/repo/images/$w" "$wall_dir/$w"; done
    rm -rf "$clone"
    note "copied ${#missing[@]} wallpapers to $wall_dir"
fi

say "Dolphin application menu"
XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

say "Neovim: plugins (versions from lazy-lock.json), parsers, language tools, Jupyter remote plugin"
nvim --headless "+Lazy! restore" +qa
# Mason installs some language servers with npm: mise's node must be on PATH (.bash_profile adds it from the next
# login). molten (Jupyter) is a remote plugin of the conda env "nvim" created above: register it.
PATH="$HOME/.local/share/mise/shims:$PATH" nvim --headless \
    -c "lua require('nvim-treesitter').install(vim.g.treesitter_parsers):wait(300000)" \
    +MasonToolsInstallSync +UpdateRemotePlugins +qa

say "Done"
note "Not handled here: logging in to apps (Chrome, Mullvad, Discord), wallpapers in ~/aesthetic-wallpapers,"
note "TPM2 unlock, SSH hardening. Reboot if the initramfs, groups or PAM files changed."
