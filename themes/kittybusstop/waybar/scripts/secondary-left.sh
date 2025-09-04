#!/bin/bash
# Secondary monitor - workspace 5
current=$(hyprctl monitors -j | jq -r '.[] | select(.name=="HDMI-A-1") | .activeWorkspace.id')
ws=5
if [ "$ws" -eq "$current" ]; then
  output="<span color='#000000' bgcolor='#ffffff' font_weight='900'> ▓▓ $ws ▓▓ </span>"
else
  if hyprctl workspaces -j | jq -e ".[] | select(.id==$ws)" >/dev/null; then
    output="<span color='#ffffff' font_weight='700'> ░░ $ws ░░ </span>"
  else
    output="<span color='#666666' font_weight='500'> ── $ws ── </span>"
  fi
fi
echo "$output"
