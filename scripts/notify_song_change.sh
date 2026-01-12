#!/usr/bin/env bash

# Song change notification script
# Monitors playerctl for song changes and sends notifications
# Filters out empty, placeholder, and invalid song titles

# Function to check if a song title is valid
is_valid_song() {
    local song="$1"

    # Return false (1) if empty
    [[ -z "$song" ]] && return 1

    # Return false if just whitespace
    [[ -z "${song// /}" ]] && return 1

    # Return false if just a dash or multiple dashes
    [[ "$song" =~ ^-+$ ]] && return 1

    # Return false if just underscores
    [[ "$song" =~ ^_+$ ]] && return 1

    # Return false if "N/A" or "n/a"
    [[ "${song,,}" == "n/a" ]] && return 1

    # Return false if "Unknown" (case insensitive)
    [[ "${song,,}" == "unknown" ]] && return 1

    # Return false if "No players found"
    [[ "$song" == *"No players found"* ]] && return 1

    # Song is valid
    return 0
}

# Main loop - follow playerctl metadata changes
playerctl metadata --format '{{title}}' --follow 2>/dev/null | while read -r song; do
    # Only send notification if song title is valid
    if is_valid_song "$song"; then
        # Get artist info if available
        artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)

        # Build notification message
        notify-send --urgency=low --app-name="Now Playing" "$song"
    fi
done
