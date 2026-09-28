#!/usr/bin/env bash
rofi -dmenu \
     -password \
     -p "󰌆  Password" \
     -mesg "${1:-doas requires your password}" \
     -lines 0 \
     -config "$HOME/.config/rofi/launcher-menu.rasi"
