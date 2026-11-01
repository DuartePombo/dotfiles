#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start Hyprland after logging in on the first console (tty1). When Hyprland exits, you're back at this shell.
if [[ -z $WAYLAND_DISPLAY && $(tty) == /dev/tty1 ]] && command -v hyprland-session >/dev/null; then
    hyprland-session
fi
