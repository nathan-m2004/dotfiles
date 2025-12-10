#!/bin/bash

# 1. Receive path from Waypaper
# clean the path just in case
path=$(echo "$1" | sed 's/\\//g')

if [ ! -f "$path" ]; then
    notify-send "Error" "Wallpaper not found: $path"
    exit 1
fi

# 2. Set Wallpaper with swww
# -t grow: Grows the new image from the center (looks cool)
# --transition-fps 60: Smooth animation
swww img "$path" --transition-type simple --transition-fps 60 --transition-duration 2

# 3. Generate Colors (Pywal)
# -n: Skip setting wallpaper (swww already did it)
wal -i "$path" -n

# 3. Update Firefox
pywalfox update

spicetify apply -n

# 4. Reload UI Apps
swaync-client -rs
pkill -SIGUSR2 waybar

# 5. Update Lock Screen (Hyprlock)
# Just link the new wallpaper to the fixed path hyprlock checks
ln -sf "$path" "$HOME/.cache/current_wallpaper.jpg"