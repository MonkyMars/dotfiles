#!/usr/bin/env bash

action="$1"

#node_id=$(pw-dump | jq -r '.[] | select(.info.props."application.name" == "PipeWire ALSA [spotify_player]" and .info.props."media.class" == "Stream/Output/Audio") | .id')
node_id=$(wpctl status \
  | awk '/Streams:/,0' \
  | awk '/spotify/ {print $1}' \
  | tr -d '.')


if [ -z "$node_id" ]; then
    notify-send --urgency=low --app-name=Volume --hint=string:x-canonical-private-synchronous:spotify_volume "spotify_player not running"
    exit 1op
fi

if [ "$action" == "up" ]; then
    wpctl set-volume -l 1.0 "$node_id" 5%+
elif [ "$action" == "down" ]; then
    wpctl set-volume -l 1.0 "$node_id" 5%-
fi

volume=$(wpctl get-volume "$node_id" | awk '{printf "%.0f%%\n", $2 * 100}')
notify-send --urgency=low --app-name=Volume --hint=string:x-canonical-private-synchronous:spotify_volume "$volume"
