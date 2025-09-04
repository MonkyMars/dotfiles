#!/bin/bash

# Get monitor and workspace range from arguments
MONITOR="$1"
WORKSPACE_RANGE="$2"

# Parse workspace range (e.g., "1-4" or "5-6")
IFS='-' read -r START_WS END_WS <<< "$WORKSPACE_RANGE"

# Get current workspace
CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.id')

# Get all workspaces
WORKSPACES=$(hyprctl workspaces -j)

# Build workspace array
WORKSPACE_BUTTONS=""

for ((i=START_WS; i<=END_WS; i++)); do
    # Check if workspace exists and has windows
    WS_EXISTS=$(echo "$WORKSPACES" | jq -r --arg ws "$i" '.[] | select(.id == ($ws | tonumber)) | .id')
    WS_WINDOWS=$(echo "$WORKSPACES" | jq -r --arg ws "$i" '.[] | select(.id == ($ws | tonumber)) | .windows')

    # Set icon based on workspace number
    case $i in
        1) ICON="󰎤" ;;
        2) ICON="󰎧" ;;
        3) ICON="󰎪" ;;
        4) ICON="󰎭" ;;
        5) ICON="󰎱" ;;
        6) ICON="󰎳" ;;
        7) ICON="󰎶" ;;
        8) ICON="󰎹" ;;
        *) ICON="󰊠" ;;
    esac

    # Determine class based on state
    if [ "$i" -eq "$CURRENT_WS" ]; then
        CLASS="active"
    elif [ -n "$WS_EXISTS" ] && [ "$WS_WINDOWS" -gt 0 ]; then
        CLASS="occupied"
    else
        CLASS="empty"
    fi

    # Build button HTML
    WORKSPACE_BUTTONS="$WORKSPACE_BUTTONS<span class=\"workspace $CLASS\" onclick=\"hyprctl dispatch workspace $i\">$ICON</span>"
done

# Output JSON for Waybar
echo "{\"text\":\"$WORKSPACE_BUTTONS\", \"class\":\"workspaces\"}"
