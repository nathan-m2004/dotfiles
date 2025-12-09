#!/usr/bin/env bash

folder=$1

WALLPAPER_DIR="$HOME/Pictures/Wallpapers/$folder"
CURRENT_WALL=$(hyprctl hyprpaper listloaded)

# Get a random JPEG wallpaper that is not the current one
WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)

# Check if the selected wallpaper is a valid JPEG
if file "$WALLPAPER" | grep -qE 'JPEG image data'; then
	# Apply the selected wallpaper
	hyprctl hyprpaper reload ,"$WALLPAPER"
	wal -i "$WALLPAPER"
else
	echo "Selected file is not a valid JPEG."
fi

