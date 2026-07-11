#!/usr/bin/env bash

# Find the first battery (e.g., BAT0, BAT1)
BATTERY=$(ls /sys/class/power_supply/ | grep -E '^BAT' | head -n 1)

if [ -z "$BATTERY" ]; then
    # No battery on this system (e.g. desktop), exit silently
    exit 0
fi

BAT_PATH="/sys/class/power_supply/$BATTERY"

# Set thresholds
LOW_BATTERY=20
CRITICAL_BATTERY=10

# Tracking variables to avoid spamming
notified_low=false
notified_critical=false

while true; do
    if [ ! -d "$BAT_PATH" ]; then
        exit 1
    fi

    capacity=$(cat "$BAT_PATH/capacity")
    status=$(cat "$BAT_PATH/status")

    if [ "$status" = "Discharging" ]; then
        if [ "$capacity" -le "$CRITICAL_BATTERY" ]; then
            if [ "$notified_critical" = false ]; then
                notify-send -u critical -i battery-empty "Bateria Crítica" "A bateria está em ${capacity}%! Conecte o carregador imediatamente."
                notified_critical=true
                notified_low=true
            fi
        elif [ "$capacity" -le "$LOW_BATTERY" ]; then
            if [ "$notified_low" = false ]; then
                notify-send -u normal -i battery-caution "Bateria Fraca" "A bateria está em ${capacity}%."
                notified_low=true
                notified_critical=false
            fi
        else
            notified_low=false
            notified_critical=false
        fi
    else
        # Charging or Full, reset notification flags
        notified_low=false
        notified_critical=false
    fi

    sleep 60
done
