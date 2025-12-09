#!/usr/bin/env bash

# Set the wallpaper folder from the first argument.
folder="$1"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers/$folder"

# Check if the wallpaper directory exists.
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Error: Wallpaper directory '$WALLPAPER_DIR' not found." >&2
    exit 1
fi

# Get the currently set wallpaper using hyprctl.  We only want the filename.
CURRENT_WALL=$(hyprctl hyprpaper listloaded | awk '{print $2}' | tr -d ',') # Extract filename

# Find all JPEG files in the directory, excluding the current wallpaper's filename.
# Use a more robust method to find JPEGs (check file header) and handle spaces in filenames.
WALLPAPERS=($(find "$WALLPAPER_DIR" -type f -print0 |
    while IFS= read -r -d $'\0' file; do
        if [[ $(file "$file" | grep -q 'JPEG image data') ]]; then
            # Extract the filename for comparison
            filename=$(basename "$file")
            # Add to the array only if it's not the current wallpaper
            if [[ "$filename" != "$(basename "$CURRENT_WALL")" ]]; then
                echo "$file"
            fi
        fi
    done
))

# Check if any new wallpapers were found.
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "No new JPEG wallpapers found in '$WALLPAPER_DIR' (excluding the current one)." >&2
    exit 1
fi

# Generate a random index to select a wallpaper from the array.
random_index=$((RANDOM % ${#WALLPAPERS[@]}))

# Get the random wallpaper file path.
WALLPAPER="${WALLPAPERS[$random_index]}"

# Apply the selected wallpaper using hyprctl.  Include error handling.
if ! hyprctl hyprpaper reload ,"$WALLPAPER"; then
    echo "Error: Failed to set wallpaper using hyprctl." >&2
    exit 1
fi

# Apply the wallpaper to pywal.  Include error handling.
if ! wal -i "$WALLPAPER"; then
    echo "Error: Failed to set wallpaper using wal." >&2
    exit 1
fi

echo "Wallpaper changed to: $WALLPAPER"
exit 0