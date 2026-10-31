#!/bin/bash

# Directory containing your wallpapers
WALLPAPER_DIR="$HOME/aesthetic-wallpapers/images"

# Find all image files (png, jpg, jpeg) in the directory and its subdirectories
# If your images are only in the top level, you can simplify the find command.
# We use -print0 and shuf -z -n 1 for safe handling of filenames with spaces or special characters.
RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | shuf -z -n 1)

# Check if a wallpaper was found
if [ -n "$RANDOM_WALLPAPER" ]; then

  # Kill the process first before creating one. This prevents continously adding more backgrounds to memory if cycling.
  pkill -f "swaybg -i"
  # Set the wallpaper using swaybg
  # You can add other swaybg options here, like -m fill, -m stretch, etc.
  swaybg -i "$RANDOM_WALLPAPER" -m fill
else
  echo "No wallpapers found in $WALLPAPER_DIR" >&2
  # Optional: Fallback to a default wallpaper if none are found
  # swaybg -i /path/to/default/wallpaper.png -m fill
fi
