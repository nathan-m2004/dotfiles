#!/bin/bash

# Check if hyprsunset is running
if pgrep -x "hyprsunset" > /dev/null; then
    # If running, kill it
    killall hyprsunset
else
    # If not running, start it in the background
    # Change '6000' to your preferred default temperature
    hyprsunset --temperature 6000 &
fi

# Wait a tiny bit for the process to start/stop
sleep 0.1

# Signal Waybar to refresh the module immediately (Signal 9)
pkill -SIGRTMIN+9 waybar