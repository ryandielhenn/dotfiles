#!/usr/bin/env bash

capacity=$(cat /sys/class/power_supply/BAT0/capacity)
stat=$(cat /sys/class/power_supply/BAT0/status)

if ["$stat" = "Charging"]; then
  echo "󱐋 $capacity%"
else
  echo "󰁿 $capacity%"
fi
