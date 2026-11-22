#!/usr/bin/env bash
# Render the ocean wallpapers (ocean.py): per screen a seamless 24-second loop at 12 fps (MP4, for mpvpaper) and a still (PNG,
# the first frame, for swaybg when mpvpaper isn't there).
#
#   render.sh [output folder]        default: ~/Pictures/wallpapers/ocean
#
# Needs python3, rsvg-convert (librsvg) and ffmpeg, all already on helios. About 10 minutes, on all cores but one.
# The frames go to a temporary folder under ~/.cache (on disk: /tmp is in RAM) and are deleted afterwards.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$HOME/Pictures/wallpapers/ocean}
fps=12      # the motion is slow: 12 frames a second look smooth and cost half the decoding of 24
loop=24     # seconds; every motion repeats exactly once per loop
jobs=$(( $(nproc) > 1 ? $(nproc) - 1 : 1 ))

mkdir -p "$out" "${XDG_CACHE_HOME:-$HOME/.cache}"
work=$(mktemp -d "${XDG_CACHE_HOME:-$HOME/.cache}/ocean-render.XXXXXX")
trap 'rm -rf "$work"' EXIT

for screen in front laptop right; do
    echo "ocean: rendering $screen ($(( fps * loop )) frames)..."
    mkdir -p "$work/$screen"
    # one frame: SVG from ocean.py at time i/fps, then PNG (the inner sh gets its values as $1..$6)
    # shellcheck disable=SC2016
    seq 0 $(( fps * loop - 1 )) | xargs -P "$jobs" -I{} sh -c '
        f=$(printf "%s/%04d" "$1" "$2")
        python3 "$3/ocean.py" "$4" "$f.svg" "$(awk -v i="$2" -v r="$5" "BEGIN { print i / r }")" "$6" &&
        rsvg-convert "$f.svg" -o "$f.png" && rm "$f.svg"' _ "$work/$screen" {} "$here" "$screen" "$fps" "$loop"
    ffmpeg -hide_banner -loglevel error -y -framerate "$fps" -i "$work/$screen/%04d.png" \
        -c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -movflags +faststart "$work/$screen.mp4"
    # replace the old files only when the new ones are complete (a running mpvpaper keeps the old one open)
    mv "$work/$screen.mp4" "$out/$screen.mp4"
    cp "$work/$screen/0000.png" "$out/$screen.png.tmp" && mv "$out/$screen.png.tmp" "$out/$screen.png"
    rm -rf "${work:?}/$screen"
done
echo "ocean: done, in $out (\`wallpaper start\` shows them)"
