#!/bin/bash

WORKSPACE_KITTY=6
WORKSPACE_ZED=1
WORKSPACE_BROWSER=2

FOUND_PROJECT=$(fd "$1" ~/Coding | head -n 1)
[[ -z "$FOUND_PROJECT" ]] && { echo "No project found for '$1'"; exit 1; }

# Spawn 3 kitty terminals in project folder
for i in {1..3}; do
    kitty -e zsh -c "cd '$FOUND_PROJECT'; clear; exec zsh" &
    sleep 0.5  # increase delay so window is registered
    hyprctl dispatch movetoworkspace $WORKSPACE_KITTY
done

# Open ZED in workspace 1
zed "$FOUND_PROJECT" &
sleep 0.5
hyprctl dispatch movetoworkspace $WORKSPACE_ZED

# Open Zen browser in workspace 2
flatpak run app.zen_browser.zen &
sleep 1  # Flatpak apps can be slower, give it more time
hyprctl dispatch movetoworkspace $WORKSPACE_BROWSER
