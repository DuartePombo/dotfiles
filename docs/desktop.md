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
| `Alt+Return` | terminal (kitty); in Office windows it goes to the app instead (Excel's new line in a cell, see below) |
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
| `Alt+F` / `Alt+Shift+F` | fullscreen, covering the bar (like F11) / maximize, keeping the bar. Again to go back |
| `Alt+V` | float / tile the window |
| `Alt+P` | pseudo-tile |
| `Alt+scroll` | next / previous workspace |
| `Alt+left drag` / `Alt+right drag` | move / resize a window |
| `Super+Shift+S` or `Print` | screenshot, like Windows' Snipping Tool: the screen freezes, drag an area or click a window (`Esc` cancels). It's copied to the clipboard and saved in `~/Pictures/Screenshots`; click the notification to draw on it (satty: `Enter` copies, saves and closes) |
| `Shift+Print` | screenshot of the whole screen under the mouse (same clipboard, folder and notification) |
| `Super+Shift+R` | screen recording: drag an area or click a window, recording starts (red `● REC` in the bar). Press again or click `● REC` to stop. MP4 in `~/Videos/Recordings`, with the computer's sound (no microphone); the notification plays it (Haruna) or shows it in the folder |
| `Alt+F9` | random wallpaper from `~/Pictures/wallpapers` (curated list: `packages/wallpapers.txt`) |
| `Alt+Tab` / `Alt+Shift+Tab` | back to the previous window (any workspace or screen) / cycle the windows of this workspace |
| `Super+V` | clipboard history (cliphist): pick an entry, then `Ctrl+V`. `cliphist wipe` empties it |
| `Super+.` | emoji picker (rofimoji): the emoji is typed where the cursor is |
| Volume, mute, mic, brightness, media keys | work as labelled, also on the lock screen; volume and brightness show a popup (swayosd) |

## Workspace layout (every app has a home)
Work on 1–5, personal on 6–10. Docked, each workspace lives on a fixed screen; on the laptop alone all are on its
screen. Start the apps from `Alt+D` by these names and they open on their workspace by themselves.

| # | App (`Alt+D` name) | Screen when docked |
|---|---|---|
| 1 | Work projects: kitty + tmux session `work` (`fz` / `Ctrl+b f` switch projects, `claude` in a tmux window) | front monitor |
| 2 | Chrome (work): its own data folder, sign in with the work account; links from Slack open here | front monitor |
| 3 | Slack | laptop |
| 4 | Work notes: Neovim in `~/notes/work`; `Super+Shift+S`, then `p` (or `Space p i`) pastes the screenshot | laptop |
| 5 | Terminal (free) | front monitor |
| 6 | Chrome (personal): opens links from all other apps | front monitor |
| 7 | WhatsApp (WhatsApp Web in its own window; scan the QR code once) | laptop |
| 8 / 9 / 10 | free | front / laptop / laptop |

The bar shows each home as number + icon (work 1–5, a gap, personal 6–10; free ones just the number): waybar
`config` ("format-icons") and `style.css`.

Rules: `hyprland.lua` ("Fixed homes for apps"), screens: `hosts/helios/.../host.lua`, launchers:
`~/.local/bin/app-launch`. A second window of the same app also goes home; `Alt+Shift+number` moves it.

Links: the default browser is `~/.local/bin/open-link`. Links from Slack open in Chrome (work), all others in
Chrome (personal), and that Chrome comes to the front. More work apps: its `work_apps` list. Chrome runs with
`--no-default-browser-check` (chrome-flags.conf), so it doesn't offer to replace this.

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
  `trust` makes it reconnect by itself. To forget a device: `bluetoothctl remove <MAC>`.
- Glove80 (factory layout; hold Magic, the bottom-left key of the left half, then tap):
  - BT slots: Magic + Backspace (0), Delete (1), the thumb key above Backspace (2), the one above Delete (3).
    Magic + Left Alt: type over the USB cable.
  - Tap Magic: thumb-key lights for 10 s. White = typing goes there, green = connected, red = remembers a
    computer that isn't connected, purple = free.
  - Pair a new computer: select a purple slot (or select one and clear it with Magic + F1; Magic + F10 clears
    all slots), then pair "Glove80" from the computer. One computer per slot.
  - If pairing fails, both sides must forget it: Magic + F1 on that slot, and remove it on the computer.
  - At the disk password prompt Bluetooth isn't running: the cable is needed (Magic + Left Alt if typing goes
    to another computer).
- Wi-Fi: nm-applet (tray), `nmtui`, or `nmcli device wifi list` / `nmcli device wifi connect "<SSID>" --ask`.
- Power profiles: `powerprofilesctl get`, `powerprofilesctl set power-saver|balanced|performance`.
- VPN: Mullvad app, or `mullvad status` / `mullvad connect` / `mullvad disconnect`.

## Backups (home folder → USB stick)
- Plug in the USB stick labelled "Ventoy": a backup starts by itself ("Backing up…", then "Backup done … You can
  unplug the stick"). A daily check at 12:00 backs up if the stick stays plugged in, and reminds you when the last
  backup is older than 7 days. Only changes are copied; versions kept: 7 daily, 4 weekly, 12 monthly.
- restic, encrypted with the password in `~/.config/restic/password` (only on this laptop; **keep a copy elsewhere**,
  without it the backups can't be opened). Backups live in `helios-backup/restic` on the stick, next to the ISOs
  (`.ventoyignore` keeps Ventoy's boot menu from scanning them). Skipped: `~/.config/restic/excludes.txt`
  (caches, Steam, Miniforge, Chrome data, VS Code's server, the Claude Code program and other things that are
  reinstalled or re-synced). No size limit: only the stick's free space; each backup adds just the changes.
- Only this stick is ever written to: any stick labelled Ventoy is first mounted read-only, and the backup runs only
  if it holds the repository whose ID is in `~/.config/restic/repository-id` (local) and that opens with the password.
  Other pens: nothing happens (not labelled Ventoy) or a read-only look and unmount (another Ventoy stick).
- By hand: `backup-usb` (or `systemctl --user start backup-usb`); last run's details: `~/.local/state/backup-usb/last.log`.
- Restore (stick plugged in and mounted, e.g. click it in Dolphin):
  ```
  export RESTIC_REPOSITORY=/run/media/$USER/Ventoy/helios-backup/restic RESTIC_PASSWORD_FILE=~/.config/restic/password
  restic snapshots                                  # list the backups
  restic find notes.md                              # which backups have a file
  restic restore latest --target ~/restored --include ~/notes   # put a folder back (into ~/restored)
  ```
- Pieces: `~/.local/bin/backup-usb`, `~/.config/systemd/user/backup-usb*.{service,timer}`,
  `/etc/udev/rules.d/90-backup-usb.rules` (from `system/`).

## Microsoft Office (Windows VM via WinApps)
- `Alt+D` → Excel, Word, PowerPoint, OneNote: real Microsoft 365 apps in a Windows 11 VM (Docker container
  `WinApps`), each in its own window. `.xlsx`/`.docx`/`.pptx`/`.csv` open there; OnlyOffice is the second choice in
  Open With, LibreOffice opens `.odt`/`.ods`/`.odp`.
- `Alt+D` → Windows: the whole Windows desktop. Windows allows one session at a time: while Office windows are open
  it asks "Another user is signed in…": **Yes** moves the open Office apps into the desktop window, **No** cancels.
  Back to separate windows: in the Windows desktop, Start → your name → Sign out, then open Office from `Alt+D`.
- In Office windows (also OnlyOffice and LibreOffice) `Alt` + letter goes to the app: Excel's key tips (`Alt+H`…),
  `Alt+Enter`, `Alt+Q`, `Alt+F4`. `Alt+1`…`Alt+0` (+Shift), `Alt+Shift+F`, `Alt+.`, screenshots and recording stay
  the desktop's.
- Close an Office app with `Alt+F4` or its ✕ (`Alt+Q` is Office's search box there).
- Leaving an Office window with `Alt+1`…`Alt+0`, `Alt+Tab` or `Alt+.` first sends it a harmless `F24`. Otherwise
  Windows reads the lone Alt as "show the key tips", and Excel draws letter boxes over the next workspace and waits
  for a letter. If they ever appear: click into Excel, `Esc`.
- Move an Office window to another workspace with `Alt+Shift+number`. `Alt`+drag also works, but Windows sees the
  lone Alt and Excel shows its key tips (`Esc`).
- Windows must know both screens, or Office windows on the laptop screen never get their size (half drawn, clicks
  miss): XWayland puts the front monitor at x=0 and the laptop at x=1920, and without `/multimon` FreeRDP reports only
  the first one. After plugging a monitor in or out, close the Office windows and open them again.
- The VM starts by itself when an Office app opens (about 30 s). It uses 4 GB of RAM while running; stop it with
  `docker stop -t 120 WinApps` (plain `docker stop` cuts Windows off after 10 s).
- Settings: `~/.config/winapps/compose.yaml` (repo), account in `~/.config/winapps/windows.env` and `winapps.conf`
  (local only). Linux home inside Windows: `\\tsclient\home`. Web view of the VM: http://127.0.0.1:8006.
  Non-secret settings in `winapps.conf` (keep them when recreating it):
  `RDP_FLAGS="/cert:tofu /sound /microphone +home-drive /multimon"`, `RDP_TIMEOUT="120"`.

## Packages
- Update everything (repo + AUR): `paru -Syu` (pacman only: `sudo pacman -Syu`).
- Automatic upkeep (timers): `reflector.timer` weekly picks the 10 fastest fresh HTTPS mirrors near Portugal
  (`/etc/xdg/reflector/reflector.conf`, from `system/`); `paccache.timer` weekly keeps the 3 newest versions of each
  package in the cache; `btrfs-scrub@-.timer` monthly checks the disk for silent corruption
  (`sudo btrfs scrub status /`). `systemctl list-timers` shows when they run next.
- Add a package: put it in `~/dotfiles/packages/pacman.txt` (AUR: `aur.txt`; helios-only: `hosts/helios/pacman.txt`)
  first, then `sudo pacman -S --needed - < ~/dotfiles/packages/pacman.txt` (AUR: `paru -S --needed - < …/aur.txt`).
- Every pacman run takes snapshots before and after: see [snapshots.md](snapshots.md) to undo one.

## Dotfiles
- Configs in `~` are symlinks into `~/dotfiles`. After adding files: `cd ~/dotfiles && stow -R -t ~ home`
  (helios-specific: `stow -R -d hosts/helios -t ~ home`).

## Development
- Shell (bash + fzf): `Ctrl+R` search history, `Ctrl+T` insert a file, `Alt+C` jump into a folder, `**` + `Tab`
  fuzzy-complete a path (`nvim **<Tab>`). `Tab` completes commands too (git, pacman, systemctl...). History is
  shared between terminals; a command started with a space isn't saved.
- `fz`: pick a project folder and jump into a tmux session for it (`tmux-sessionizer`). It lists the folders in
  `~/pombo/projects`, plus those in each path listed in `~/.tmux-sessionizer.local` (one per line; that file stays
  on this machine, so work paths never reach the repo).
- tmux (prefix `Ctrl+b`): `f` projects, `h`/`j`/`k`/`l` panes, `r` reload config, `[` copy mode (`v` select, `y` copy).
- Node: mise (`mise use -g node@lts`, per project `mise use node@22`). Python: `uv` for pip-style projects;
  conda (Miniforge) for environments: `conda activate jupyter && jupyter lab`.
- Docker: `docker ps`, `docker compose up -d`. Images and containers live on their own subvolumes and are not in
  the snapshots.
- Neovim: `nvim`, set up as an IDE (Python envs, run, debug, Jupyter notebooks): keys in [neovim.md](neovim.md).
