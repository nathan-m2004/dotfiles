#!/bin/sh

# Start the idle daemon with our "suspend-only" config
# This runs in the background
hypridle &

# Store the Process ID (PID) of hypridle
HYPRIDLE_PID=$!

# Run hyprlock.
# The script will *wait here* until hyprlock exits (i.e., you unlock).
hyprlock

# --- Execution resumes here after you unlock ---

# Kill the hypridle process we started, canceling the suspend timer.
kill $HYPRIDLE_PID