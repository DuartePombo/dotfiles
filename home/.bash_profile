#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# mise's shims (node, npm...) for everything started from this login, including GUI apps launched by Hyprland
# (Neovim's Mason installs and js-debug need node even when Neovim isn't started from an interactive shell)
export PATH="$HOME/.local/share/mise/shims:$PATH"

# Start Hyprland after logging in on the first console (tty1). When Hyprland exits, you're back at this shell.
if [[ -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]] && command -v hyprland-session >/dev/null; then
    hyprland-session
fi
