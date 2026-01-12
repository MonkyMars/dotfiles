#!/usr/bin/env bash

action="$1"

# Try to find VLC first (case-insensitive), if not found then try Spotify
node_id=$(wpctl status | awk '/Streams:/,0 {if(tolower($0) ~ /vlc/) {gsub("\\.","",$1); print $1; exit}}')
if [ -z "$node_id" ]; then
    node_id=$(wpctl status | awk '/Streams:/,0 {if($0 ~ /spotify/) {gsub("\\.","",$1); print $1; exit}}')
    node_id=$(wpctl status | awk '/Streams:/,0 {if(tolower($0) ~ /spotify/) {gsub("\\.","",$1); print $1; exit}}')
fi


if [ -z "$node_id" ]; then
    notify-send --urgency=low --app-name=Volume --hint=string:x-canonical-private-synchronous:spotify_volume "Spotify or VLC not running"
    exit 1op
fi

if [ "$action" == "up" ]; then
    wpctl set-volume -l 1.0 "$node_id" 5%+
elif [ "$action" == "down" ]; then
    wpctl set-volume -l 1.0 "$node_id" 5%-
fi

volume=$(wpctl get-volume "$node_id" | awk '{printf "%.0f%%\n", $2 * 100}')
notify-send --urgency=low --app-name=Volume --hint=string:x-canonical-private-synchronous:spotify_volume "$volume"
