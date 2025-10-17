#!/bin/bash

# Read the target window that was stored before opening clipboard
if [ -f /tmp/clipboard-target ]; then
    target_window=$(head -1 /tmp/clipboard-target)
    target_class=$(tail -1 /tmp/clipboard-target)
else
    # Get the most recent non-clipboard, non-discord window
    target_window=$(hyprctl clients -j | jq -r '.[] | select(.class != "floating-clipmenu" and .class != "kitty" and .class != "discord" and .mapped == true and .hidden == false) | .address' | head -1)
    target_class=$(hyprctl clients -j | jq -r --arg addr "$target_window" '.[] | select(.address == $addr) | .class')
fi

# Run fzf and capture selection
chosen=$(cliphist list | fzf --height=40% --reverse --no-sort --prompt="Clipboard > " --inline-info)

# Exit if nothing was chosen (user pressed Esc)
if [ -z "$chosen" ]; then
    exit 0
fi

# Decode the selection and copy to clipboard
content=$(cliphist decode <<< "$chosen")
wl-copy <<< "$content" 2>/dev/null

# Focus the target window using its address
if [ -n "$target_window" ] && [ "$target_window" != "null" ]; then
    hyprctl dispatch focuswindow address:$target_window
else
    # Fallback: cycle to next non-discord window
    hyprctl dispatch focuswindow class:firefox || hyprctl dispatch focuswindow class:zed || hyprctl dispatch cyclenext
fi

# Wait for focus to restore
sleep 0.1

# Type the content
wtype -M ctrl -k v

# Optional: close this window after typing
sleep 0.1
hyprctl dispatch closewindow

# Clean up temp file
rm -f /tmp/clipboard-target
