#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# mise's shims (node, npm...) for everything started from this login, including GUI apps launched by Hyprland
# (Neovim's Mason installs and js-debug need node even when Neovim isn't started from an interactive shell)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# .NET: no usage data to Microsoft from the dotnet tools (on by default), also for VS Code's C# extension and
# Neovim's Mason, which run dotnet with this login's environment
export DOTNET_CLI_TELEMETRY_OPTOUT=1

# Qt apps' look from qt6ct (dark Catppuccin, ~/.config/qt6ct), also when started from a terminal: tmux keeps its own
# environment, so Hyprland's copy of this (hyprland.lua) doesn't reach its panes
export QT_QPA_PLATFORMTHEME=qt6ct

# Start Hyprland after logging in on the first console (tty1), always through hyprland-session: it picks docked or
# mobile mode, the graphics card and the screen layout. exec: when Hyprland exits (Ctrl+Alt+Delete → Log out), this
# login ends too and you're back at the login prompt; logging in starts the desktop again, the right way. (Started
# by hand from a shell with Hyprland or start-hyprland, the screens came up in the wrong order.)
# If the desktop won't start at all: Ctrl+Alt+F2 gives a second console, without the automatic start.
if [[ -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]] && command -v hyprland-session >/dev/null; then
    exec hyprland-session
fi
