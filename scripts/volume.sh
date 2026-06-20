#!/usr/bin/env bash

# 1. Get DEFAULT_SINK volume
sink_vol=$(wpctl get-volume @DEFAULT_SINK@)

# 2. Split the string into a native Bash array
# [0]="Volume:"  [1]="0.05"  [2]="[MUTED]" (if present)
read -r -a vol_parts <<< "$sink_vol"

# 3. Extract the raw decimal and muted toggle from the array
raw_num=${vol_parts[1]:-0}
muted=${vol_parts[2]}

# 4. strip the decimal point
clean_num=${raw_num/./}

# 5. Use base-10 arithmetic to drop leading zeros and evaluate as an integer
volume=$((10#$clean_num))

if [ "$muted" = "[MUTED]" ]; then
  echo "󰖁"
else
  echo "󰕾 $volume%"
fi
