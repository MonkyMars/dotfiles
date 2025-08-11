#!/bin/bash

# Check if directory was passed
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/folder"
  exit 1
fi

TARGET_DIR="$1"

# Find all .webp files and recompress them
find "$TARGET_DIR" -type f -iname "*.webp" | while read -r file; do
  echo "Recompressing: $file"

  # Temporary file to avoid in-place corruption
  tmp_file="${file%.webp}_tmp.webp"

  # Recompress with lossy compression at 95% quality
  magick "$file" -quality 95 -define webp:lossless=false "$tmp_file"

  if [ -f "$tmp_file" ]; then
    mv "$tmp_file" "$file"
    echo "✓ Done: $file"
  else
    echo "✗ Failed to compress: $file"
  fi
done
