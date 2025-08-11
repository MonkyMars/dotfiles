#!/bin/bash
set -u # Exit on error, undefined vars error, and fail on pipe errors

# Set all the variants available in the dotfiles directory
VARIANTS=$(ls -1 /mnt/Y/dotfiles 2>/dev/null | grep -E '^[a-zA-Z0-9_-]+$')
# Check for required argument
if [ $# -ne 1 ]; then
  echo "❌ Usage: $0 <variant>"
  echo "   Available variants:"
  echo "$VARIANTS"
  echo "   Example: $0 kittybusstop"
  exit 1
fi

if ! echo "$VARIANTS" | grep -q "^$VARIANT$"; then
  echo "❌ Invalid variant: $VARIANT"
  echo "   Available variants:"
  echo "$VARIANTS"
  exit 1
fi

VARIANT="$1"
SOURCE_DIR="/mnt/Y/dotfiles/$VARIANT"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config_backups/${VARIANT}_$(date +%Y%m%d_%H%M%S)"
WALLPAPER_SOURCE="$SOURCE_DIR/wallpaper.webp"
WALLPAPER_DEST="$HOME/Documents/Wallpapers/wallpaper.webp"

echo "🔍 Running safety checks for variant: $VARIANT..."

# Check if USB is mounted and source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ Error: Source directory $SOURCE_DIR not found."
  echo "   Available variants:"
  if [ -d "/mnt/Y/dotfiles" ]; then
    ls -1 "/mnt/Y/dotfiles" | grep -E '^(kittybusstop|silversurfer|brutal)$' || echo "   (none found)"
  else
    echo "   /mnt/Y/dotfiles not found or not mounted"
  fi
  exit 1
fi

# Check if source has actual content
if [ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
  echo "❌ Error: Source directory is empty"
  exit 1
fi

# Show what will be synced
echo "📋 Found these items in $VARIANT variant:"
for item in "$SOURCE_DIR"/*; do
  if [ -e "$item" ]; then
    name=$(basename "$item")
    if [ -d "$item" ] && [ "$name" != "wallpaper.webp" ]; then
      status=""
      if [ -e "$CONFIG_DIR/$name" ]; then
        status=" (will replace existing)"
      else
        status=" (new)"
      fi
      echo "   📁 $name$status"
    elif [ -f "$item" ] && [ "$name" == "wallpaper.webp" ]; then
      status=""
      if [ -f "$WALLPAPER_DEST" ]; then
        status=" (will replace existing)"
      else
        status=" (new)"
      fi
      echo "   🖼️  wallpaper.webp$status"
    fi
  fi
done

echo ""
echo "🔍 Each item will be confirmed individually before copying."
echo ""

# Confirmation prompt to continue
read -rp "🤔 Continue with individual confirmations? (y/N): " reply
if [[ ! "$reply" =~ ^[Yy]$ ]]; then
  echo "❌ Cancelled by user"
  exit 0
fi

echo "🔄 Syncing $VARIANT dotfiles from $SOURCE_DIR to $CONFIG_DIR..."

# Ensure directories exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$BACKUP_DIR"

synced_count=0

# Loop through all items in source directory except wallpaper.webp
for item in "$SOURCE_DIR"/*; do
  name=$(basename "$item")
  if [ "$name" == "wallpaper.webp" ]; then
    continue
  fi

  if [ -d "$item" ]; then
    echo ""
    echo "📁 Processing directory: $name"
    echo "   Source: $item"
    echo "   Destination: $CONFIG_DIR/$name"

    if [ -e "$CONFIG_DIR/$name" ]; then
      echo "   ⚠️  This will REPLACE your existing $name config"
      echo "   💾 Existing config will be backed up to: $BACKUP_DIR/$name"
    else
      echo "   ✨ This will create a new $name config"
    fi

    while read -t 0.1 -r -n 1000; do :; done # flush input buffer
    read -rp "   🤔 Copy $name config? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      if [ -e "$CONFIG_DIR/$name" ]; then
        echo "   💾 Backing up existing $name..."
        cp -r "$CONFIG_DIR/$name" "$BACKUP_DIR/$name"
        rm -rf "$CONFIG_DIR/$name"
      fi
      echo "   📋 Copying $name config..."
      cp -r "$item" "$CONFIG_DIR/$name"
      echo "   ✅ Successfully copied $name"
      ((synced_count++))
    else
      echo "   ⏭️  Skipped $name"
    fi
  fi
done

STARSHIP_SOURCE="$SOURCE_DIR/starship.toml"
STARSHIP_DEST="$HOME/.config/starship.toml"

if [ -f "$STARSHIP_SOURCE" ]; then
  echo ""
  echo "📄 Processing starship.toml"
  echo "   Source: $STARSHIP_SOURCE"
  echo "   Destination: $STARSHIP_DEST"

  if [ -f "$STARSHIP_DEST" ]; then
    echo "   ⚠️  This will REPLACE your existing starship.toml"
    echo "   💾 Existing starship.toml will be backed up to: $BACKUP_DIR/starship.toml"
  else
    echo "   ✨ This will create a new starship.toml"
  fi

  read -rp "   🤔 Copy starship.toml? (y/N): " confirm_starship
  if [[ "$confirm_starship" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$STARSHIP_DEST")"
    if [ -f "$STARSHIP_DEST" ]; then
      cp "$STARSHIP_DEST" "$BACKUP_DIR/starship.toml"
    fi
    cp "$STARSHIP_SOURCE" "$STARSHIP_DEST"
    echo "   ✅ Successfully copied starship.toml"
  else
    echo "   ⏭️  Skipped starship.toml"
  fi
fi

# Handle wallpaper
if [ -f "$WALLPAPER_SOURCE" ]; then
  echo ""
  echo "🖼️ Processing wallpaper.webp"
  echo "   Source: $WALLPAPER_SOURCE"
  echo "   Destination: $WALLPAPER_DEST"

  if [ -f "$WALLPAPER_DEST" ]; then
    echo "   ⚠️  This will REPLACE your existing wallpaper"
    echo "   💾 Existing wallpaper will be backed up to: $BACKUP_DIR/wallpaper_old.webp"
  else
    echo "   ✨ This will set a new wallpaper"
  fi

  read -rp "   🤔 Copy wallpaper? (y/N): " confirm_wallpaper
  if [[ "$confirm_wallpaper" =~ ^[Yy]$ ]]; then
    mkdir -p "$(dirname "$WALLPAPER_DEST")"
    if [ -f "$WALLPAPER_DEST" ]; then
      cp "$WALLPAPER_DEST" "$BACKUP_DIR/wallpaper_old.webp"
    fi
    cp "$WALLPAPER_SOURCE" "$WALLPAPER_DEST"
    echo "   ✅ Successfully copied wallpaper"
  else
    echo "   ⏭️  Skipped wallpaper"
  fi
else
  echo "⚠️ Wallpaper not found at $WALLPAPER_SOURCE"
fi

echo ""
echo "🎉 Sync complete!"
echo "   📊 Synced $synced_count config directories"
echo "   💾 Backups stored in: $BACKUP_DIR"
echo ""

echo "🔄 Reloading Hyprland environment..."

if command -v hyprctl >/dev/null 2>&1; then
  echo "   🪟 Reloading Hyprland config..."
  hyprctl reload >/dev/null 2>&1 & # Run in background, redirect output
  disown
else
  echo "   ⚠️ hyprctl not found - skipping Hyprland reload"
fi

if command -v waybar >/dev/null 2>&1; then
  echo "   📊 Restarting Waybar..."
  pkill waybar 2>/dev/null || true
  waybar >/dev/null 2>&1 & # Redirect stdout and stderr before backgrounding
  disown
else
  echo "   ⚠️ waybar not found - skipping"
fi

if command -v hyprpaper >/dev/null 2>&1; then
  echo "   🖼️ Restarting Hyprpaper..."
  pkill hyprpaper 2>/dev/null || true
  hyprpaper >/dev/null 2>&1 & # Same here
  disown
else
  echo "   ⚠️ hyprpaper not found - skipping"
fi

echo ""
echo "✨ Environment reloaded! Your configs should now be active."
