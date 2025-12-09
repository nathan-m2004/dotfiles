#!/bin/bash

# Define the special workspace name
WORKSPACE="monitor"
# Define the window class (must match Hyprland rule)
CLASS="sys-monitor"

# Check if the window exists using hyprctl clients
if hyprctl clients | grep -q "class: $CLASS"; then
    # If it exists, just toggle the special workspace on/off
    hyprctl dispatch togglespecialworkspace $WORKSPACE
else
    # If it doesn't exist, launch it using Alacritty
    # --class sets the Wayland app_id so Hyprland can grab it
    alacritty --class $CLASS -e btop &
fi