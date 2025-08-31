#!/bin/bash

# Workspace numbers
WORKSPACE_KITTY=6
WORKSPACE_ZED=1

# Find project folder
FOUND_PROJECT=$(fd "$1" ~/Coding | head -n 1)

if [[ -z "$FOUND_PROJECT" ]]; then
    echo "No project found for '$1'"
    exit 1
fi

# Spawn 3 kitty terminals in that folder on workspace 6
for i in {1..3}; do
    kitty -e zsh -c "cd '$FOUND_PROJECT'; exec zsh" &
    sleep 0.2
    hyprctl dispatch movetoworkspace $WORKSPACE_KITTY
done

# Open the project in zed on workspace 1
zed "$FOUND_PROJECT" &
sleep 0.2
hyprctl dispatch movetoworkspace $WORKSPACE_ZED
