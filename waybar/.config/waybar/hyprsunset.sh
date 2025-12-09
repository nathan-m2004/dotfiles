#!/bin/bash

# Check if process exists
if pgrep -x "hyprsunset" > /dev/null; then
    # Try to get temp. If command fails (during startup), default to "On"
    temperature=$(hyprctl hyprsunset temperature 2>/dev/null)
    
    if [ -z "$temperature" ]; then
        echo "Temp Starting..."
    else
        echo "${temperature}K"
    fi
else
    echo "Temp Off"
fi