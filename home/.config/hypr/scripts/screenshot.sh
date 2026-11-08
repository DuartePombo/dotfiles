#!/bin/bash
# Screenshots like Windows' Snipping Tool (Super+Shift+S and Print in hyprland.lua).
#   screenshot.sh          the screen freezes: drag over an area, or click a window. Esc cancels.
#   screenshot.sh screen   the whole screen under the mouse (Shift+Print)
# The picture is copied to the clipboard and saved in ~/Pictures/Screenshots. Clicking the notification
# opens satty to draw on it (arrows, boxes, text, highlighter, blur, crop); Enter copies, saves, closes.
set -u

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-area}" in
    area)
        # Freeze the screen first, so menus and tooltips stay put while you select.
        hyprpicker --render-inactive --no-zoom --quiet &
        freeze=$!
        trap 'kill "$freeze" 2>/dev/null' EXIT
        sleep 0.2
        # Windows on the visible workspaces become click targets; dragging selects any area.
        visible=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')
        geometry=$(hyprctl -j clients | jq -r --argjson ws "$visible" '
            .[] | select(.mapped and (.hidden | not) and (.workspace.id | IN($ws[])))
                | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -d)
        [ -n "$geometry" ] || exit 0    # Esc: nothing taken
        grim -g "$geometry" "$file"      # taken while still frozen: exactly what you saw
        ;;
    screen)
        grim -o "$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')" "$file"
        ;;
    *)
        echo "usage: screenshot.sh [area|screen]" >&2
        exit 2
        ;;
esac
[ -n "${freeze:-}" ] && kill "$freeze" 2>/dev/null

wl-copy --type image/png < "$file"

# The notification waits up to 10 s for a click; a click opens the editor.
action=$(notify-send --app-name=Screenshot --icon="$file" --expire-time=10000 \
    --action=default=Edit --action=edit="Draw on it" \
    "Screenshot copied" "Saved in ~/Pictures/Screenshots. Click to draw on it.")
if [ -n "$action" ]; then
    satty --filename "$file" --output-filename "$file" --copy-command wl-copy \
        --actions-on-enter save-to-clipboard,save-to-file,exit
fi
