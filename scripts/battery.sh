#!/usr/bin/env bash

readonly battery=/sys/class/power_supply/BAT0

if [ -f "$battery" ]; then
  read -r capacity < "$battery/capacity"
  read -r status < "$battery/status"

  if [[ $status == Charging ]]; then
    icon='󱐋'
  else
    icons=(󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
    icon=${icons[capacity / 10]}
  fi

  printf '%s %s%%\n' "$icon" "$capacity"
fi
