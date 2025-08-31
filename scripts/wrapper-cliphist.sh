#!/bin/bash

# Get current window info
current_info=$(hyprctl activewindow -j)
current_class=$(echo "$current_info" | jq -r '.class')

# If we're already in a clipboard-related window, find the real target
if [[ "$current_class" == "floating-clipmenu" || "$current_class" == "kitty" ]]; then
    # Try multiple approaches to find the right window

    # Method 1: Get windows on current workspace, excluding clipboard windows
    TARGET_WINDOW=$(hyprctl workspaces -j | jq -r '.[] | select(.windows > 0) | .lastwindow' | head -1)

    # Method 2: If that fails, get the largest/most recent window by PID
    if [[ -z "$TARGET_WINDOW" || "$TARGET_WINDOW" == "null" ]]; then
        TARGET_WINDOW=$(hyprctl clients -j | jq -r '.[] | select(.class != "floating-clipmenu" and .class != "kitty" and .mapped == true and .hidden == false) | "\(.pid) \(.address)"' | sort -nr | head -1 | cut -d' ' -f2)
    fi

    # Method 3: Last resort - get any visible non-clipboard window
    if [[ -z "$TARGET_WINDOW" || "$TARGET_WINDOW" == "null" ]]; then
        TARGET_WINDOW=$(hyprctl clients -j | jq -r '.[] | select(.class != "floating-clipmenu" and .class != "kitty" and .mapped == true) | .address' | head -1)
    fi

    TARGET_CLASS=$(hyprctl clients -j | jq -r --arg addr "$TARGET_WINDOW" '.[] | select(.address == $addr) | .class')
else
    # Use the current window as target
    TARGET_WINDOW=$(echo "$current_info" | jq -r '.address')
    TARGET_CLASS=$(echo "$current_info" | jq -r '.class')
fi

# Debug: show what we captured
echo "Captured target: $TARGET_CLASS ($TARGET_WINDOW)" >> /tmp/clipboard-debug.log
echo "Available windows:" >> /tmp/clipboard-debug.log
hyprctl clients -j | jq -r '.[] | select(.class != "floating-clipmenu" and .class != "kitty") | "\(.class): \(.address) (mapped: \(.mapped), hidden: \(.hidden))"' >> /tmp/clipboard-debug.log

# Write target info to a temp file
echo "$TARGET_WINDOW" > /tmp/clipboard-target
echo "$TARGET_CLASS" >> /tmp/clipboard-target

# Launch the clipboard selector
kitty --class=floating-clipmenu -e ~/dotfiles/scripts/clipmenu-fzf.sh
