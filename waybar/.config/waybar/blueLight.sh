#!/bin/bash

if pgrep hyprsunset > /dev/null
then
    temperature=$(hyprctl hyprsunset temperature)
    echo 'Temp: '$temperature'K'
else
    echo "Temp: Off"
fi