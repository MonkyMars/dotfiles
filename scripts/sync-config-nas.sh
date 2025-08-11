#!/bin/bash

MOUNT_POINT="/home/monky/nas"
PROFILE="$1"
WALLPAPER="$2"
SRC_PROFILE="/home/monky/dotfiles/$PROFILE"
DST_POINT="/home/monky/nas/levi/dotfiles/$PROFILE"
DST_CODING="/home/monky/nas/levi/Coding"
SRC_CODING="/home/monky/Coding"
SRC_WALLPAPER="/home/monky/Documents/Wallpapers/$WALLPAPER"
DST_WALLPAPER="/home/monky/nas/levi/dotfiles/$PROFILE/$WALLPAPER"

EXCLUDES=(
  --exclude='.git/'
  --exclude='.vercel/'
  --exclude='node_modules/'
  --exclude='.venv/'
  --exclude='target/'
)

# Validate params
if [[ -z "$PROFILE" || -z "$WALLPAPER" ]]; then
  echo "Usage: $0 <profile-name> <wallpaper-file>"
  exit 1
fi

# Validate source folders/files
if [[ ! -d "$SRC_PROFILE" ]]; then
  echo "Error: source profile folder '$SRC_PROFILE' does not exist."
  exit 1
fi

if [[ ! -f "$SRC_WALLPAPER" ]]; then
  echo "Error: wallpaper '$SRC_WALLPAPER' does not exist."
  exit 1
fi

if mountpoint -q "$MOUNT_POINT"; then
  echo "NAS is mounted, syncing configs..."

  # Remove folders in destination that don't exist in source
  if [[ -d "$DST_POINT" ]]; then
    echo "Cleaning up extra folders in destination..."
    find "$DST_POINT" -mindepth 1 -maxdepth 1 -type d | while read -r dst_dir; do
      folder_name=$(basename "$dst_dir")
      if [[ ! -d "$SRC_PROFILE/$folder_name" ]]; then
        echo "Removing extra folder: $dst_dir"
        rm -rf "$dst_dir"
      fi
    done
  fi

  # Sync dotfiles subfolders
  for item in fastfetch hypr kitty zed rofi waybar; do
    if [[ -d "$SRC_PROFILE/$item" ]]; then
      rsync -av --delete "$SRC_PROFILE/$item/" "$DST_POINT/$item/"
    fi
  done

  # Sync individual files
  for file in starship.toml clipmenu-fzf.sh wrapper-cliphist.sh; do
    if [[ -f "$SRC_PROFILE/$file" ]]; then
      rsync -av "$SRC_PROFILE/$file" "$DST_POINT/"
    fi
  done

  # Sync coding folder with exclusions
  echo "Syncing Coding folder with exclusions..."
  rsync -av --delete "${EXCLUDES[@]}" "$SRC_CODING/" "$DST_CODING/"

  # Sync wallpaper
  echo "Copying wallpaper '$WALLPAPER'..."
  mkdir -p "$(dirname "$DST_WALLPAPER")"
  rsync -av "$SRC_WALLPAPER" "$DST_WALLPAPER"

  echo "Sync complete."
else
  echo "NAS mount not found at $MOUNT_POINT, skipping sync."
fi
