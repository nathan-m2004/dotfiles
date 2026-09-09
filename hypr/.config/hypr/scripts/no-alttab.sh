#!/usr/bin/env bash

# Evita abrir múltiplos banners se a pessoa teclar Alt+Tab repetidamente
pidof rofi >/dev/null && exit 0

timeout 2 rofi -e "🚫 AQUI NÃO TEM ALT+TAB 🚫" -theme-str '
window {
    fullscreen: true;
    background-color: rgba(0, 0, 0, 0.85);
}
mainbox {
    background-color: transparent;
}
textbox {
    font: "RobotoMono Nerd Font Bold 48";
    text-color: #ff3333;
    horizontal-align: 0.5;
    vertical-align: 0.5;
}
'
