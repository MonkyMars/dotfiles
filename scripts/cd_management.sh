#!/usr/bin/env bash

running=$(pgrep vlc >/dev/null 2>&1 && echo "yes" || echo "no")
if [ "$running" == "yes" ]; then
    # Kill existing cdda instances
    pkill -f "vlc"
else
    vlc --intf dummy cdda:// >/dev/null 2>&1 &
fi

notify-send --urgency=low --app-name=CD Player --hint=string:x-canonical-private-synchronous:cd_player "CD Player toggled"
