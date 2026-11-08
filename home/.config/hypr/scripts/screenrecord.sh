#!/bin/bash
# Screen recording like the Snipping Tool's (Super+Shift+R in hyprland.lua, or click ● REC in waybar).
#   Press once: drag over an area or click a window (Esc cancels). Recording starts; waybar shows ● REC.
#   Press again: it stops and is saved as MP4 in ~/Videos/Recordings. The notification plays it (mpv) or
#   shows it in Dolphin, ready to drag into a chat or an email.
# No sound. H.264 at 30 fps, which plays everywhere (browsers, Discord, phones).
set -u

dir="$HOME/Videos/Recordings"
state="${XDG_RUNTIME_DIR:-/tmp}/screenrecord"   # the file being recorded, and wf-recorder's log
refresh_bar() { pkill -RTMIN+8 waybar; }        # signal 8 = custom/recording in waybar/config

if pgrep -x wf-recorder >/dev/null; then
    # Stop. wf-recorder finishes the file on Ctrl+C (SIGINT).
    pkill -INT -x wf-recorder
    while pgrep -x wf-recorder >/dev/null; do sleep 0.1; done
    refresh_bar
    file=$(cat "$state" 2>/dev/null)
    rm -f "$state"
    if [ ! -s "$file" ]; then
        notify-send --app-name=Recording --urgency=critical "Recording failed" "Nothing was saved."
        exit 1
    fi
    action=$(notify-send --app-name=Recording --expire-time=10000 \
        --action=default=Play --action=folder="Show in folder" \
        "Recording saved" "${file/#$HOME/\~}")
    case "$action" in
        default) xdg-open "$file" ;;
        folder)  dolphin --select "$file" ;;
    esac
    exit 0
fi

# Start: windows on the visible workspaces become click targets; dragging selects any area.
visible=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')
geometry=$(hyprctl -j clients | jq -r --argjson ws "$visible" '
    .[] | select(.mapped and (.hidden | not) and (.workspace.id | IN($ws[])))
        | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -d)
[ -n "$geometry" ] || exit 0    # Esc: nothing recorded

# H.264 needs an even width and height
read -r position size <<<"$geometry"
width=${size%x*}
height=${size#*x}
geometry="$position $((width / 2 * 2))x$((height / 2 * 2))"

mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
echo "$file" >"$state"
wf-recorder --geometry "$geometry" --framerate 30 --codec libx264 --pixel-format yuv420p \
    --codec-param preset=veryfast --codec-param crf=23 -f "$file" >/dev/null 2>"$state.log" &
sleep 0.5
if ! pgrep -x wf-recorder >/dev/null; then
    notify-send --app-name=Recording --urgency=critical "Recording didn't start" "$(tail -n 2 "$state.log")"
    rm -f "$state"
    exit 1
fi
refresh_bar
