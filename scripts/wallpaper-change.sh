#!/usr/bin/env bash
set -euo pipefail

# Noctalia theme sync — runs on wallpaper change
# Usage: script <wallpaper_path>

THEME_DIR="$HOME/.local/share/themes/Noctalia"
GTK3="$THEME_DIR/gtk-3.0/gtk.css"
GTK4="$THEME_DIR/gtk-4.0/gtk.css"
GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS="$HOME/.config/gtk-4.0/settings.ini"

# Validate input
if [[ $# -lt 1 || ! -f "$1" ]]; then
    echo "Usage: $0 <wallpaper_path>" >&2
    exit 1
fi

WALLPAPER="$1"

notify-send "Wallpaper received"

# 1. Create theme directories
mkdir -p "$THEME_DIR/gtk-3.0" "$THEME_DIR/gtk-4.0"

# 2. Generate palette from wallpaper and render GTK CSS
#    noctalia generates noctalia-extensions.css alongside the rendered CSS
echo "🎨 Generating palette from wallpaper..."
noctalia theme "$WALLPAPER" \
    --render gtk4:"$GTK4" \
    --render gtk3:"$GTK3"

# 3. Ensure GTK settings point to Noctalia
for settings in "$GTK3_SETTINGS" "$GTK4_SETTINGS"; do
    if [[ -f "$settings" ]]; then
        if grep -q '^gtk-theme-name=' "$settings"; then
            sed -i 's/^gtk-theme-name=.*/gtk-theme-name=Noctalia/' "$settings"
        else
            echo "gtk-theme-name=Noctalia" >> "$settings"
        fi
    fi
done

echo "✅ Noctalia theme synced"
