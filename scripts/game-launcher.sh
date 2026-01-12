#!/bin/bash

launcher=$(printf "Heroic Games Launcher\nPrism Launcher\nSteam" | fzf --prompt="Choose a launcher: ")

if [ -z "$launcher" ]; then
  exit 0
fi

# Fully detach the launcher process so it survives after this terminal closes
case "$launcher" in
  "Prism Launcher")
    setsid prismlauncher >/dev/null 2>&1 &
    ;;
  "Heroic Games Launcher")
    setsid heroic >/dev/null 2>&1 &
    ;;
  "Steam")
    setsid steam >/dev/null 2>&1 &
    ;;
esac

# Close this terminal window (if running in kitty)
sleep 0.3
if [ -n "$KITTY_PID" ]; then
  kitty @ close-window --self
else
  exit 0
fi
