#!/bin/bash

# Workspace icons (extend this map if needed)
declare -A icons=(
  [5]="󰎱"
  [6]="󰎳"
  [7]="󰎶"
  [8]="󰎹"
)

# Get the currently active workspace on HDMI-A-1
current=$(hyprctl monitors -j | jq -r '.[] | select(.name=="HDMI-A-1") | .activeWorkspace.id')
output=""

for ws in 5 6 7 8; do
  icon=${icons[$ws]:-$ws}  # fallback to number if no icon defined

  if [ "$ws" -eq "$current" ]; then
    # Active workspace: subtle brackets
    output+="| $icon | "
  else
    if hyprctl workspaces -j | jq -e ".[] | select(.id==$ws)" >/dev/null; then
      # Occupied: just icon
      output+=" $icon  "
    else
      # Empty: dimmed with dots
      output+=" $icon  "
    fi
  fi
done

echo "$output"
