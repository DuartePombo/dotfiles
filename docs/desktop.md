# Desktop cheat sheet (helios)

## Logging in
- After the disk passphrase, log in on the first console (tty1). Hyprland starts by itself; the same password
  unlocks the keyring (Chrome and VS Code passwords).
- `Ctrl+Alt+Delete`: a menu to lock, log out, restart or shut down (Cancel/Esc does nothing). Log out quits Hyprland
  and brings you back to the login prompt; logging in starts it again (`.bash_profile` runs `exec hyprland-session`).
  Never start Hyprland by hand with `Hyprland` or `start-hyprland`: only `hyprland-session` sets docked/mobile mode,
  the graphics card and the screen layout (started directly, the screens came up in the wrong order).
- Other consoles: `Ctrl+Alt+F2` … `F6` (useful if Hyprland won't start).

## Hyprland keys
`Alt` is the main modifier.

| Keys | Action |
|---|---|
| `Alt+Return` | terminal (kitty); in Office windows it goes to the app instead (Excel's new line in a cell, see below) |
| `Alt+D` | app launcher (wofi): type any words of the name, in any case (`chrome work` → Chrome (work)) |
| `Alt+E` | file manager (Dolphin) |
| `Alt+Q` | close window |
| `Ctrl+Alt+Delete` | menu: lock / log out / restart / shut down (no single key quits the desktop) |
| `Alt+.` or `Super+L` | lock the screen (hyprlock; `Super+L` like Windows, also from the Windows desktop) |
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
| `Super+Shift+S` or `Print` | screenshot, like Windows' Snipping Tool: the screen freezes, drag an area or click a window (`Esc` cancels). It's copied to the clipboard and saved in `~/Pictures/Screenshots`; click the notification to draw on it (satty: opens large, with the pen in red; `Ctrl+wheel` zooms, `Alt` + right-drag resizes, `Alt+Shift+F` fills the screen; keys `b` pen, `z` arrow, `r` box, `t` text, `1`-`5` colours; `Enter` copies, saves and closes) |
| `Shift+Print` | screenshot of the whole screen under the mouse (same clipboard, folder and notification) |
| `Super+Shift+R` | screen recording: drag an area or click a window, recording starts (red `● REC` in the bar). Press again or click `● REC` to stop. MP4 in `~/Videos/Recordings`, with the computer's sound (no microphone); the notification plays it (Haruna) or shows it in the folder |
| `Alt+F9` / `Alt+Shift+F9` | a random still wallpaper from `~/Pictures/wallpapers` on all screens (curated list: `packages/wallpapers.txt`) / back to the moving ocean (see Wallpaper) |
| `Alt+Tab` / `Alt+Shift+Tab` | back to the previous window (any workspace or screen) / cycle the windows of this workspace |
| `Super+V` | clipboard history (cliphist): pick an entry, then `Ctrl+V`. `cliphist wipe` empties it |
| `Super+Left` / `Super+Right` | volume down / up (hold to keep going), like the laptop's volume keys: for the Glove80, which has none |
| `Super+A` | **a**udio: choose the speaker and microphone (e.g. the laptop's speakers while the earbuds are in); also a right-click on the bar's volume. `Space` or `Enter` picks and the menu stays (✓ moves), `Esc` closes. Bluetooth headphones take over again when they next connect |
| `Super+B` / `Super+Shift+B` | the **b**ars: hide them all (the windows take the space) or bring them back / pin the front monitor's bar (see Bar and tray) |
| `Super+.` | emoji picker (rofimoji): the emoji is typed where the cursor is |
| Volume, mute, mic, brightness, media keys | work as labelled, also on the lock screen; volume and brightness show a popup (swayosd) |

## Workspace layout (every app has a home)
Work on 1–5, personal on 6–10. Docked, each workspace lives on a fixed screen; on the laptop alone all are on its
screen. Start the apps from `Alt+D` by these names and they open on their workspace by themselves.

| # | App (`Alt+D` name) | Screen when docked |
|---|---|---|
| 1 | Work projects: kitty + tmux session `work` (`fz` / `Ctrl+b f` switch projects, `claude` in a tmux window) | front monitor |
| 2 | Chrome (work): its own data folder, sign in with the work account; links from Slack and Zoom open here | front monitor |
| 3 | Slack | laptop |
| 4 | Work notes: Neovim in the work notes folder (named in `~/.work-notes.local`, local only; default `~/notes/work`); `Super+Shift+S`, then `p` (or `Space p i`) pastes the screenshot | laptop |
| 5 | Terminal (free), next to the projects | right monitor |
| 6 | Chrome (personal): opens links from all other apps | front monitor |
| 7 | WhatsApp (WhatsApp Web in its own window; scan the QR code once) | laptop |
| 8 / 9 | free | front monitor / laptop |
| 10 | Windows: the whole Windows desktop in fullscreen, where Office lives (see Microsoft Office below) | right monitor |

A Chrome started by a program (an RPA robot through Selenium: no window name of its own, class `google-chrome`)
opens on the right monitor, in whatever workspace shows there, to watch it next to the code (`host.lua`; the laptop
alone: where you are).

At login, Work projects, Chrome (work), Slack, Work notes, Chrome (personal) and WhatsApp open in their homes
silently, while the screens start on empty workspaces: 8 in front, 5 on the right and 9 on the laptop (the laptop
alone: 9). The list:
`hyprland.lua`, autostart; the starting workspaces: `host.lua`.

If the bar ever disappears from one screen with its space still reserved: it was (re)started while that screen showed
a fullscreen window (Windows on 10), and Hyprland 0.57 never shows it again there. Restart the bars from a normal
workspace: `bar start`.

The bar shows each home as number + icon (work 1–5, a gap, personal 6–10; free ones just the number; 10, Windows, is blue; the workspace each screen shows glows orange): waybar
`config` ("format-icons") and `style.css`.

Rules: `hyprland.lua` ("Fixed homes for apps"), screens: `hosts/helios/.../host.lua`, launchers:
`~/.local/bin/app-launch`. A second window of the same app also goes home; `Alt+Shift+number` moves it.

Links: the default browser is `~/.local/bin/open-link`. Links from Slack and Zoom (also Zoom's "Sign in with
Google") open in Chrome (work), all others in
Chrome (personal), and that Chrome comes to the front. More work apps: its `work_apps` list. Chrome runs with
`--no-default-browser-check` (chrome-flags.conf), so it doesn't offer to replace this.
Which Chrome each link went to, and why: `~/.local/state/open-link.log`.

Zoom (screen sharing): in `~/.config/zoomus.conf` (Zoom's own file, `[General]`) `xwayland=false` and
`enableWaylandShare=true`: Zoom then runs as a native Wayland app and shares through the desktop's picker. Through
XWayland (`xwayland=true`, the default) the share was black and the sharing bar ignored clicks. Set them while Zoom
is closed (it rewrites the file on exit, keeping both). In Zoom's own share dialog just press Share: the desktop's
picker (Monitors / Windows / Workspaces / Region) is where you choose.
Zoom starts through `~/.local/bin/zoom` (also its menu entry, `~/.local/share/applications/Zoom.desktop`, which
replaces the package's): it switches off Qt's texture atlas (`QSG_ATLAS_SIZE_LIMIT=1`); natively on the NVIDIA GPU
the icons were black. Drawing Zoom in software also fixed the icons but made all video black.

## Bar and tray
- Hiding the bars: `Super+B` hides every bar and the windows grow into the strip (unlike `Alt+F`, they keep sharing
  the screen); `Super+B` again brings them back (if any bar is hidden, it shows them all).
- The front monitor is an OLED, which can burn in when something sits still on it for hours: its bar is hidden at
  login and hides itself again 5 minutes after `Super+B` shows it. `Super+Shift+B` (or a click on the pigeon) pins it:
  it stays, and the pigeon in the middle of the bar turns orange, with a ball and chain on its leg. Again: unpinned, it hides 5 minutes
  later. The laptop's and the right monitor's bars (LCDs) stay until `Super+B` hides them. On the laptop alone there's
  one bar and `Super+B` simply toggles it.
- How: `~/.local/bin/bar` (`bar start` restarts the bars) runs the front monitor's bar as a second waybar; which
  monitor that is: `BAR_FRONT_MONITOR` in `host.lua`. The pigeons: `pigeon.svg`, `pigeon-pinned.svg` in waybar's folder.
- Waybar: click **network** for `nmtui`, **volume** for pavucontrol, **CPU/memory** for htop, **power profile** to
  switch profiles. The **clock** always shows the time; hover it for today's date and a calendar (weeks start on Monday,
  ISO week numbers; mouse wheel: other months, right click: whole year, middle click: back to today). The **bell** (top right, red dot = notifications
  waiting): click for the notification centre, right click for do not disturb (bell crossed out).
- Tray: Wi-Fi (nm-applet), Bluetooth (blueman).

## Wallpaper
- The ocean: a gently moving wallpaper on each screen, one continuous fog across the desk. Laptop: a jellyfish with a
  whale far away; front: five jellyfish, one of them a moon jellyfish; right: one jellyfish under soft light rays.
  Neon line art in the Catppuccin colours, seamless 12-second loops at 24 frames a second (12 fps with 24 s loops was
  tried: only ~0.5% CPU and <1 W less, and 24 looked better).
- Played by mpvpaper (AUR), one per screen, decoded on the NVIDIA card (nvdec: less CPU than vaapi or software).
  Without mpvpaper the same scenes show as stills (swaybg). Cost, measured 2026-11-22 with all three playing at 24 fps:
  about 920 MB of RAM (mostly mpv itself), 17-20% of one CPU core (under 2% of the processor), +8.5 W on the NVIDIA
  card, and ~1.4 GB of the card's 6 GB video memory (each player's decoding
  context; `hwdec-extra-frames=2` instead of mpv's 6 saves ~170 MiB). Software decoding would use less video memory
  but 5x the CPU and more RAM. Only the front moving
  would cost about a third. Alt+F9 (a still) frees it all, e.g. before a game. mpvpaper's auto-pause (`-p`)
  rarely triggers: the terminals are slightly see-through and the gaps between windows show the wallpaper.
- `wallpaper start` (at login, `Alt+Shift+F9`), `wallpaper random` (`Alt+F9`): `~/.local/bin/wallpaper`. Which screen
  shows which scene: `~/.config/hypr-host/wallpapers.conf` (by model, like the monitors).
- The pictures are drawn by a program, not downloaded: `hosts/helios/wallpapers/ocean.py` (the scenes, the fog, the
  creatures), `render.sh` turns them into `~/Pictures/wallpapers/ocean/{laptop,front,right}.mp4` + `.png` (about 10
  minutes; setup.sh does it on a new install). Change a scene: edit ocean.py, run render.sh, then `wallpaper start`.

## Look (colours)

One palette everywhere: Catppuccin Mocha (dark blue-grey, light text) with peach for "selected / active", as in the
bar, kitty and VS Code.

- Terminal (kitty, `~/.config/kitty/kitty.conf`): blue-black background `#141420` (darker than the editors, like the
  VS Code terminal) with Catppuccin's text colours, 8 px padding, 10% taller lines, 90% opacity over Hyprland's blur
  (`decoration.blur` in hyprland.lua, size 5, passes 2), and a quick grey cursor trail on jumps (`cursor_trail_*`).
  Changes apply to open windows after `kill -USR1` to kitty (or a new window).
- Neovim: its terminal window has the file tree's colour; one status line at the bottom for the window you're in,
  thin lines between windows (`WinSeparator`, tokyonight's setup in init.lua).
- tmux bar (`~/.config/tmux/tmux.conf`): session in blue, current window in peach, date and time; `Ctrl+b r` reloads.
- Menus (wofi: `Alt+D`, `Super+V`, `Super+.`, `Ctrl+Alt+Delete`): `~/.config/wofi/style.css` (colours) and `config`
  (size, icons, search). A change shows the next time a menu opens.
- The clipboard menu and the power menu don't remember past picks (`--cache-file /dev/null`): the clipboard stays
  newest first and Cancel stays first. Otherwise wofi moves your most used pick to the top (one restart put Restart
  first) and keeps every picked clip in plain text in `~/.cache/wofi-dmenu`. The app launcher keeps its memory: apps
  you start often come first.
- Hidden from the launcher: technical tools that other packages bring along (webcam and GPS test tools, the Java
  console and shell, lstopo). Each has a small file in `home/.local/share/applications/` with `Hidden=true`; the
  program stays installed. Delete the file to show it again; add one with the same file name as the app's
  `/usr/share/applications/*.desktop` to hide another.
- Notifications and the bell's panel: `~/.config/swaync/style.css` (the package's style with these colours; apply
  with `swaync-client --reload-css`). Volume/brightness pop-up: `~/.config/swayosd/style.css` (applies when
  swayosd-server starts, i.e. at login). Screenshot editor: `~/.config/satty/overrides.css` and `config.toml`.
- GTK apps (Bluetooth, Volume Control, network windows, satty, file dialogs) are dark (Adwaita-dark), and the system
  says "prefer dark", so Chrome on its "Device" theme, websites that offer a dark mode, Slack/VS Code set to follow
  the system, all go dark too. Icons: Papirus-Dark. These live in GNOME's settings store, set by setup.sh:
  `gsettings get org.gnome.desktop.interface color-scheme` (`prefer-dark`; `default` = light again).
  To keep one app light: its own theme setting (Chrome: Settings → Appearance → Mode).
- Qt and KDE apps (Dolphin, Okular, Gwenview, Haruna, Kdenlive, the password prompt): qt6ct gives them the Breeze
  style, the same palette and Papirus icons (`~/.config/qt6ct/`: `qt6ct.conf` and `colors/catppuccin-mocha-peach.conf`;
  switched on by `QT_QPA_PLATFORMTHEME=qt6ct` in hyprland.lua and `.bash_profile`). Outside the KDE desktop, KDE apps
  reset to light Breeze unless they name a colour scheme themselves: dolphinrc, okularrc, gwenviewrc, kdenliverc, arkrc
  have `[UiSettings] ColorScheme=CatppuccinMochaPeach` (the scheme: `~/.local/share/color-schemes/`; the same colours
  in `~/.config/kdeglobals`). Those files are written by the apps too, so they're copied once from `home-defaults/`.
  A new KDE app that comes up light: its Settings → Color Scheme → "Catppuccin Mocha (peach)".
  The `qt6ct` app (in `Alt+D`) shows and changes these settings; what it saves lands in the repo.

## Opening files (Dolphin)

- Double-click a code or text file (.py, .ts/.tsx, .cs, .json, .sh, .lua, .yaml...): Neovim opens it in a new kitty
  window, started in the file's project (its git repository, else its folder), so `Space s f` and the file tree
  show the whole project. Markdown opens in Okular (preview), HTML in the browser, PDFs in Okular.
- Right-click a file or folder, or the empty space of a folder: **Open in VS Code** (the folder, or the file inside
  its project, like Windows' "Open with Code") and **Open in Neovim**. Open With lists the other apps.
- kitty from Dolphin: `Shift+F4` in the folder you're viewing, `Alt+Shift+F4` (right-click → Open Terminal Here) in
  the selected folder. `F4` shows/hides Dolphin's built-in terminal panel, which needs Konsole (not installed), so
  leave it hidden.
- Scripts marked executable open in Neovim like any code file: a click never runs them (`kiorc`). Run them from
  a terminal.
- Archives (Ark): right-click files or folders → **Compress** (Here as .zip / .tar.gz, or Compress to… for a name
  and format); right-click an archive → **Extract** (Extract here, Extract to…). A double-click opens it in Ark.
  .zip, .tar.*, .7z (7zip); .rar would need `unrar` (not installed).
- Where it's set: `~/.config/mimeapps.list` (what a double-click opens), `~/.local/share/applications/nvim.desktop`
  (Neovim in kitty, replacing the package's entry; re-check it if the neovim package changes its own),
  `~/.local/bin/nvim-open` and `code-open`, `~/.local/share/kio/servicemenus/open-in-editor.desktop` (the right-click
  entries; KDE ignores the file unless it's executable), `~/.config/kdeglobals` (`TerminalApplication=kitty`).

## Idle, lock, suspend
- After 10 minutes without a key press or mouse movement the screens switch off (for the OLED: burn-in, and it does
  its panel care in standby). Nothing locks or suspends: a key or the mouse brings them back. Playing videos keep
  them on. Lock with `Alt+.` or `Super+L`.
- Closing the lid suspends; every suspend locks the screen first.
- Settings: `~/.config/hypr/hypridle.conf`, look of the lock screen: `~/.config/hypr/hyprlock.conf`.

## Graphics (NVIDIA + Intel)
- Default ("mobile"): Intel draws the desktop. Run a program on NVIDIA with `prime-run <program>`.
- The NVIDIA GPU stays powered on all the time (its power saving broke external monitors with this driver).
- Monitors on the laptop's HDMI and mini-DisplayPort ports (both wired to the NVIDIA GPU): Hyprland has to start in
  "docked" mode, which it picks by itself when a monitor is plugged in at login. Docked, monitors can be plugged in
  and out freely; plugged in while on the laptop alone: `Ctrl+Alt+Delete` → Log out, then log in again. The
  USB-C port carries no video (USB only).
- The desk, left to right: laptop | front: AOC Q27G41ZDF (27" OLED, 2560x1440) | right: Acer VG252Q (1920x1080).
  `host.lua` knows them by model, not by port, so cables can be swapped. Speeds: the front monitor does 240 Hz
  over DisplayPort, 144 over HDMI; the right one 165 over HDMI, 60 through the mini-DP→HDMI adapter (its limit). Both
  at full speed: the front monitor on the mini-DP port with a mini-DP→DP cable (DP 1.4), the right one on HDMI.
  Check: `hyprctl monitors`. Without the right monitor, its workspaces (5, 10) go to the other screens.
- Size of everything on the front monitor: scale 1.333333 (like Windows' 133%: lays out like a 1920x1080 screen, so
  all three screens sit in one row; at 1 the text was too small, 1.25 still a bit small). Bigger or
  smaller: the `scale` in its `hl.monitor` line in `host.lua`, with a value that divides 2560x1440 evenly (1.25 =
  2048x1152, 1.333333 = 1920x1080, 1.6 = 1600x900), then move the right monitor's x to 1920 + the new width and
  the laptop's y to the new height − 1080. Apply: `hyprctl reload`.
- Which mode did Hyprland start in? `journalctl -t hyprland-session`. Force one: `hyprland-session docked` or
  `hyprland-session mobile`.

## Hyprland itself
- Config: `~/.config/hypr/hyprland.lua` (Lua since Hyprland 0.57); helios-specific: `~/.config/hypr-host/host.lua`.
- Check for errors: `hyprctl configerrors`. Reload: `hyprctl reload`. Test a config without starting it:
  `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.

## Audio, Bluetooth, Wi-Fi, power
- Audio: `wpctl status` (devices, defaults), `wpctl set-default <id>`, or pavucontrol.
  The UGREEN dock's sound card ("SMI USB Display") is switched off: nothing plays through it, but apps kept picking
  it (`hosts/helios/home/.config/wireplumber/`). So are the monitors' speakers (the NVIDIA card's HDMI/DisplayPort
  audio, both monitors): Zoom kept switching to them when a screen woke up.
- Which device plays and records: Bluetooth headphones when connected (speaker and mic), otherwise the laptop.
  Switch by hand with `Super+A` (or right-click the bar's volume): `~/.local/bin/audio-switch`. A hand pick lasts
  until headphones connect again; then they take over (WirePlumber script
  `hosts/helios/home/.local/share/wireplumber/scripts/headphones-take-over.lua`: without it WirePlumber keeps the
  last pick for good, also over newly connected headphones). Volume Control's ✓ ("Set as fallback") is the same kind
  of pick.
  In Zoom set Speaker and Microphone to "Same as System" and untick "Automatically adjust microphone volume"
  (it kept lowering the laptop mic).
- Bluetooth headphones (JBL Live Pro 2): music and video in high quality (AAC). While an app uses their mic (a call)
  they switch to call mode (mono, phone quality, both ways: a Bluetooth limit, mSBC is the best they offer) and
  back a few seconds after. Anything that listens to the mic keeps them in call mode, also the Input tab of
  pavucontrol. Stuck in call mode, or no high-quality option (e.g. after restarting the sound service): reconnect
  them (`bluetoothctl disconnect <MAC>` then `connect <MAC>`, or back in the case).
- Volume: each device keeps its own level (like Windows); the volume keys change the one playing, app volumes are
  a share of it: leave apps at 100%.
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
- Logitech G502 mouse: always 1600 DPI at login (`mouse-dpi`, from the autostart). The DPI buttons next to the left
  click (rear: slower, front: faster) change it until the next login; the mouse itself wakes up at its last level
  (host mode: a startup default stored in it isn't used, and libratbag can't make its stored profile stick).
  After switching it off and on: `mouse-dpi` (or `mouse-dpi 800` for another level). Levels 400/800/1600/3200/6400:
  `ratbagctl list`, `ratbagctl <name> info`, or the Piper app.
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
- Office lives on **workspace 10, the whole Windows desktop** (since 2026-11-17): a Windows 11 VM (Docker container
  `WinApps`) shown through Remote Desktop (`sdl-freerdp3`, native Wayland). `Alt+D` → Windows opens it on the right
  monitor in fullscreen; open Excel, Word... from its Start menu or taskbar. Inside, Windows handles everything: `Alt`
  + letters (Excel's key tips), `Alt+Enter`, `Alt+Q` (Office's search), `Alt+F4`, `Alt+Tab` between Windows apps.
  Linux keeps `Alt+1`…`Alt+0` (`Alt+9`: back to Linux, `Alt+0`: back to Windows), `Alt+.` and `Super+L` (Linux's lock;
  `Win+L` never reaches Windows), `Alt+Shift+F`, screenshots and recording.
- Leaving 10 changes nothing: Windows keeps running with its files open. Leaving with an Alt key first sends Windows a
  harmless `Alt+F24`, or it would read the lone Alt as "show the key tips".
- Files: the Linux home is `\\tsclient\home` inside Windows (pin it in Explorer's Quick access). Double-clicking an
  `.xlsx`/`.docx`/`.pptx`/`.csv` in Linux opens OnlyOffice for a quick look; edit in Excel via File → Open on 10.
  LibreOffice opens `.odt`/`.ods`/`.odp`.
- WinApps' separate app windows (Excel, Word..., cmd, PowerShell, Explorer as their own windows, RemoteApp through
  XWayland) were removed from the menu: Windows allows one session, so each one kicked the desktop off ("Another user
  is signed in…"), and they often hung. After reinstalling WinApps (`winapps-setup --user
  --setupAllOfficiallySupportedApps`), keep only `windows.desktop` in `~/.local/share/applications` and run
  `update-desktop-database ~/.local/share/applications`.
- Windows locks itself when idle unless switched off once inside (Windows Terminal: `powercfg /change
  monitor-timeout-ac 0`, `powercfg /change standby-timeout-ac 0`, `powercfg /setacvalueindex scheme_current sub_none
  consolelock 0`, `powercfg /setactive scheme_current`). Its account password: `RDP_PASS` in `winapps.conf`.
- Safety: Windows' only doors (Remote Desktop, web viewer) open on 127.0.0.1, this laptop only. It keeps its internet
  for Office's licence check and security updates; browse in Linux Chrome, not in Edge.
- The VM starts when the desktop opens (about 30 s); nothing of it starts at boot or login. About 4 GB of RAM while
  it runs; stop it with `docker stop WinApps` (compose gives Windows 120 s to shut down properly).
- Settings: `~/.config/winapps/compose.yaml` (repo), account in `~/.config/winapps/windows.env` and `winapps.conf`
  (local only). Web view of the VM: http://127.0.0.1:8006.
  Non-secret settings in `winapps.conf` (keep them when recreating it):
  `RDP_FLAGS="/cert:tofu /sound /microphone +home-drive"`, `RDP_FLAGS_WINDOWS="/size:1920x1080"` (the desktop, the right monitor's size: the SDL
  client's own `/f` fails here, it reads the monitor as 64x64; Hyprland makes the window fullscreen, `hyprland.lua`),
  `RDP_FLAGS_NON_WINDOWS="/multimon"` (only for separate app windows, unused now: XWayland swaps the monitors, and
  without it Windows never resized windows on the laptop screen), `RDP_TIMEOUT="120"`.

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
