# Desktop cheat sheet (helios)

## Logging in
- After the disk passphrase, log in on the first console (tty1). Hyprland starts by itself; the same password
  unlocks the keyring (Chrome and VS Code passwords).
- `Alt+M` quits Hyprland and drops you back at the tty1 shell. Start it again with `hyprland-session`.
- Other consoles: `Ctrl+Alt+F2` … `F6` (useful if Hyprland won't start).

## Hyprland keys
`Alt` is the main modifier.

| Keys | Action |
|---|---|
| `Alt+Return` | terminal (kitty) |
| `Alt+D` | app launcher (wofi) |
| `Alt+E` | file manager (Dolphin) |
| `Alt+Q` | close window |
| `Alt+M` | quit Hyprland |
| `Alt+.` | lock the screen (hyprlock) |
| `Alt+H` / `J` / `K` / `L` | move focus left / down / up / right (vim keys) |
| `Alt+T` | toggle the split direction (side by side / stacked) |
| `Alt+1` … `Alt+0` | go to workspace 1–10 |
| `Alt+Shift+1` … `Alt+Shift+0` | move window to workspace 1–10 |
| `Alt+S` | show/hide the scratchpad workspace |
| `Alt+Shift+S` | move window to the scratchpad |
| `Alt+V` | float / tile the window |
| `Alt+P` | pseudo-tile |
| `Alt+scroll` | next / previous workspace |
| `Alt+left drag` / `Alt+right drag` | move / resize a window |
| `Print` | screenshot of a selected area to the clipboard |
| `Alt+F9` | random wallpaper from `~/Pictures/wallpapers` (curated list: `packages/wallpapers.txt`) |
| Volume, mute, mic, brightness, media keys | work as labelled, also on the lock screen |

## Bar and tray
- Waybar: click **network** for `nmtui`, **volume** for pavucontrol, **CPU/memory** for htop, **clock** for the
  notification centre, **power profile** to switch profiles.
- Tray: Wi-Fi (nm-applet), Bluetooth (blueman).

## Idle, lock, suspend
- No idle timers: the screen never dims, blanks, locks or suspends by itself. Lock with `Alt+.`.
- Closing the lid suspends; every suspend locks the screen first.
- Settings: `~/.config/hypr/hypridle.conf`, look of the lock screen: `~/.config/hypr/hyprlock.conf`.

## Graphics (NVIDIA + Intel)
- Default ("mobile"): Intel draws the desktop. Run a program on NVIDIA with `prime-run <program>`.
- The NVIDIA GPU stays powered on all the time (its power saving broke external monitors with this driver).
- Monitor on the laptop's HDMI port (it's wired to the NVIDIA GPU): Hyprland has to start in "docked" mode, which
  it picks by itself when that monitor is plugged in at login. Plugged in later: `Alt+M`, then `hyprland-session`
  at the tty1 prompt. The USB-C port carries no video (USB only).
- Which mode did Hyprland start in? `journalctl -t hyprland-session`. Force one: `hyprland-session docked` or
  `hyprland-session mobile`.

## Hyprland itself
- Config: `~/.config/hypr/hyprland.lua` (Lua since Hyprland 0.57); helios-specific: `~/.config/hypr-host/host.lua`.
- Check for errors: `hyprctl configerrors`. Reload: `hyprctl reload`. Test a config without starting it:
  `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.

## Audio, Bluetooth, Wi-Fi, power
- Audio: `wpctl status` (devices, defaults), `wpctl set-default <id>`, or pavucontrol.
- Bluetooth: blueman (tray), or `bluetoothctl`, then `power on`, `scan on`, `pair <MAC>`, `trust <MAC>`, `connect <MAC>`.
- Wi-Fi: nm-applet (tray), `nmtui`, or `nmcli device wifi list` / `nmcli device wifi connect "<SSID>" --ask`.
- Power profiles: `powerprofilesctl get`, `powerprofilesctl set power-saver|balanced|performance`.
- VPN: Mullvad app, or `mullvad status` / `mullvad connect` / `mullvad disconnect`.

## Packages
- Update everything (repo + AUR): `paru -Syu` (pacman only: `sudo pacman -Syu`).
- Add a package: put it in `~/dotfiles/packages/pacman.txt` (AUR: `aur.txt`; helios-only: `hosts/helios/pacman.txt`)
  first, then `sudo pacman -S --needed - < ~/dotfiles/packages/pacman.txt` (AUR: `paru -S --needed - < …/aur.txt`).
- Every pacman run takes snapshots before and after: see [snapshots.md](snapshots.md) to undo one.

## Dotfiles
- Configs in `~` are symlinks into `~/dotfiles`. After adding files: `cd ~/dotfiles && stow -R -t ~ home`
  (helios-specific: `stow -R -d hosts/helios -t ~ home`).

## Development
- `fz`: pick a project folder and jump into a tmux session for it (`tmux-sessionizer`). It lists the folders in
  `~/pombo/projects`, plus those in each path listed in `~/.tmux-sessionizer.local` (one per line; that file stays
  on this machine, so work paths never reach the repo).
- tmux (prefix `Ctrl+b`): `f` projects, `h`/`j`/`k`/`l` panes, `r` reload config, `[` copy mode (`v` select, `y` copy).
- Node: mise (`mise use -g node@lts`, per project `mise use node@22`). Python: `uv` for pip-style projects;
  conda (Miniforge) for environments: `conda activate jupyter && jupyter lab`.
- Docker: `docker ps`, `docker compose up -d`. Images and containers live on their own subvolumes and are not in
  the snapshots.
- Neovim: `nvim`, set up as an IDE (Python envs, run, debug, Jupyter notebooks): keys in [neovim.md](neovim.md).
