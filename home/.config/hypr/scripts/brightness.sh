#!/bin/bash
# Brightness keys: change the laptop panel's brightness, then show the level in swayosd's popup.
# brightnessctl does the change (through systemd-logind, no extra permissions); swayosd only displays it.
#   brightness.sh up | down
set -u

case "${1:-}" in
    up)   brightnessctl -e4 -n2 set 5%+ >/dev/null ;;
    down) brightnessctl -e4 -n2 set 5%- >/dev/null ;;
    *)    echo "usage: brightness.sh up|down" >&2; exit 2 ;;
esac
# brightnessctl -m: device,class,current,percent%,max
percent=$(brightnessctl -m | cut -d, -f4 | tr -d '%')
swayosd-client --custom-icon display-brightness-symbolic \
    --custom-progress "$(awk -v p="$percent" 'BEGIN { printf "%.2f", p / 100 }')" >/dev/null 2>&1 || true
