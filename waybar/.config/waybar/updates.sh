#!/bin/bash

# Calculate updates
# checkupdates = official repo updates (requires pacman-contrib)
# yay -Qua = AUR updates
official=$(checkupdates 2>/dev/null | wc -l)
aur=$(yay -Qua 2>/dev/null | wc -l)

total=$((official + aur))

if [ "$total" -gt 0 ]; then
    # (Same as before)
    text="$total"
    tooltip="Official: $official\nAUR: $aur"
    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"updates\"}"
else
    # CHANGE THIS PART:
    # Instead of empty text, show a checkmark or "0"
    echo "{\"text\": \"0\", \"tooltip\": \"System is up to date\", \"class\": \"none\"}"
fi