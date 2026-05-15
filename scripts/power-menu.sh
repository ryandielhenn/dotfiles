#!/bin/bash

options="Lock\nReboot\nShutdown"

chosen=$(printf "$options" | dmenu -p "Power:" \
    -nb "#2b3339" -nf "#d3c6aa" \
    -sb "#a7c080" -sf "#2b3339" \
    -fn "monospace:size=10")

case "$chosen" in
    Lock)     i3lock -c 000000 ;;
    Reboot)   systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
