#!/usr/bin/env bash

# Wait for a valid Wayland display
for i in $(seq 1 20); do
    if [ -n "$WAYLAND_DISPLAY" ] && [ -S "/run/user/$(id -u)/$WAYLAND_DISPLAY" ]; then
        break
    fi
    sleep 0.5
done

# Retry loop — respawns if it exits unexpectedly
while true; do
    gpu-screen-recorder \
        -w screen \
        -s 1920x1080 \
        -f 30 -r 30 \
        -c mp4 -k h264 \
        -bm cbr -q 2500 \
        -a "default_output|device:alsa_input.usb-MV-SILICON_fifine_Microphone_20190808-00.analog-stereo" \
        -o /home/monky/data/Videos/clips
    sleep 2  # brief pause before respawn
done
