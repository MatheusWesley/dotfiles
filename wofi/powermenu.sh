#!/bin/bash

# Define the menu entries
entries="🔁 reboot\n⛔ shutdown\n🙋🏽‍♂️ logout\n🌙 suspend"

# Show the menu and capture the selection
selected=$(echo -e "$entries" | wofi --width 280 --height 260 --dmenu --hide-search=true --hide-scroll --cache-file /dev/null | awk '{print tolower($2)}')

# Check if a valid selection was made
if [ -z "$selected" ]; then
  exit 0 # Exit if no option was selected
fi

# Execute commands based on the selection
case $selected in
logout)
  exec hyprctl dispatch exit NOW
  ;;
suspend)
  exec systemctl suspend
  ;;
reboot)
  exec systemctl reboot
  ;;
shutdown)
  exec systemctl poweroff -i
  ;;
*)
  echo "Opção inválida: $selected" >&2
  exit 1
  ;;
esac
