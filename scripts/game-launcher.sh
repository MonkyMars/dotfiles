#!/usr/bin/env bash

launcher=$(printf "Heroic Games Launcher\nPrism Launcher\nSteam" |
    fzf --prompt="Choose a launcher: ")

# Exit if nothing was selected
[ -z "$launcher" ] && exit 0

# Launch selected application independently
case "$launcher" in
    "Heroic Games Launcher")
        setsid -f heroic >/dev/null 2>&1
        ;;
    "Prism Launcher")
        setsid -f prismlauncher >/dev/null 2>&1
        ;;
    "Steam")
        setsid -f steam >/dev/null 2>&1
        ;;
esac

# Close this Kitty window
sleep 0.3
if [ -n "$KITTY_PID" ]; then
    kitty @ close-window --self
else
    exit 0
fi
