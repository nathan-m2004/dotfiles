#!/bin/bash

# Define the special workspace name
WORKSPACE="monitor"
# Define the window class (must match Hyprland rule)
CLASS="sys-monitor"

# Check if the window exists using hyprctl clients
if hyprctl clients | grep -q "class: $CLASS"; then
    # If it exists, just toggle the special workspace on/off
    hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$WORKSPACE\")"
else
    # If it doesn't exist, launch it using Alacritty
    # --class sets the Wayland app_id so Hyprland can grab it
    MONITOR_CMD="btop"
    command -v btop &>/dev/null || MONITOR_CMD="htop"
    alacritty --class "$CLASS" -e "$MONITOR_CMD" &
fi