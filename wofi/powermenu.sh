#!/bin/bash

# Define the menu entries
entries="🔁 reboot\n⛔ shutdown\n🙋🏽‍♂️ logout\n🌙 suspend"

# Show the menu and capture the selection in lowercase
selected=$(echo -e "$entries" | wofi --width 280 --height 210 --dmenu -p "Power Menu" -n --style ~/.config/wofi/themes/powermenu.css --hide-scroll --cache-file /dev/null | tr '[:upper:]' '[:lower:]')

# Check if a valid selection was made
if [ -z "$selected" ]; then
  exit 0 # Exit if no option was selected
fi

# Execute commands based on the selection
case $selected in
  *logout*)
    hyprctl dispatch exit NOW
    ;;
  *suspend*)
    systemctl suspend
    ;;
  *reboot*)
    systemctl reboot
    ;;
  *shutdown*)
    systemctl poweroff -i
    ;;
  *)
    echo "Opção inválida: '$selected'. Tente novamente." >&2
    exit 1
    ;;
esac

