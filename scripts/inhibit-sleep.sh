#!/bin/bash

PIDFILE="/tmp/sleep-inhibit.pid"

if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE")
    kill "$pid" 2>/dev/null
    rm -f "$PIDFILE"
    xset s on
    xset dpms 600 600 600
    pkill -RTMIN+11 dwmblocks
    notify-send "Sleep enabled" "System will sleep normally" -t 3000
else
    systemd-inhibit --what=sleep:idle --who="DWM" --why="Manual inhibit" --mode=block sleep infinity &
    echo $! > "$PIDFILE"
    xset s off
    xset dpms 0 0 0
    pkill -RTMIN+11 dwmblocks
    notify-send "Sleep inhibited" "System will not sleep automatically" -t 3000
fi
