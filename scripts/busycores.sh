#!/usr/bin/env bash
# Prints "busy/total" using /proc/stat. No JSON, just text.

THRESH=20  # consider a thread "busy" if active% >= THRESH

readarray -t A < <(grep -E '^cpu[0-9]+' /proc/stat)
sleep 0.15
readarray -t B < <(grep -E '^cpu[0-9]+' /proc/stat)

busy=0
total=0

for i in "${!A[@]}"; do
  IFS=' ' read -r _ u1 n1 s1 i1 w1 irq1 sirq1 steal1 _ <<<"${A[$i]}"
  IFS=' ' read -r _ u2 n2 s2 i2 w2 irq2 sirq2 steal2 _ <<<"${B[$i]}"

  act1=$((u1+n1+s1+irq1+sirq1+steal1))
  act2=$((u2+n2+s2+irq2+sirq2+steal2))
  tot1=$((u1+n1+s1+i1+w1+irq1+sirq1+steal1))
  tot2=$((u2+n2+s2+i2+w2+irq2+sirq2+steal2))

  dtot=$((tot2 - tot1))
  (( dtot <= 0 )) && continue

  dbusy=$((act2 - act1))
  pct=$((100 * dbusy / dtot))

  (( total++ ))
  (( pct >= THRESH )) && (( busy++ ))
done

printf "%d/%d\n" "$busy" "$total"
