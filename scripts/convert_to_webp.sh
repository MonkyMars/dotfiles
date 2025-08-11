#!/bin/bash
# ========== CONFIG ==========
DELETE_ORIGINALS=1 # Set to 1 to auto-delete originals after confirmation
EXTENSIONS=("jpg" "jpeg" "png" "heic" "bmp" "tiff" "gif")
QUALITY=80 # WebP quality (1-100)
# ============================

# Function to check ImageMagick HEIC support
check_heic_support() {
  if magick -list format | grep -qi "HEIC.*HEIF"; then
    return 0
  else
    return 1
  fi
}

# Check if required tools exist
if ! command -v magick &>/dev/null; then
  echo "❌ Error: 'convert' (ImageMagick) not found. Install it first."
  exit 1
fi

# Check ImageMagick's HEIC support
IMAGEMAGICK_HEIC=0
if check_heic_support; then
  IMAGEMAGICK_HEIC=1
  echo "✅ ImageMagick has HEIC support built-in"
else
  echo "⚠️  ImageMagick lacks HEIC support"
fi

# Check for heif-convert as fallback
HEIF_CONVERT_AVAILABLE=0
if command -v heif-convert &>/dev/null; then
  HEIF_CONVERT_AVAILABLE=1
  echo "✅ heif-convert found as fallback"
else
  if [ "$IMAGEMAGICK_HEIC" -eq 0 ]; then
    echo "💡 For HEIC support, install: sudo dnf install libheif-tools"
  fi
fi

# Check argument
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/folder"
  exit 1
fi

TARGET_DIR="$1"

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Error: Directory '$TARGET_DIR' does not exist."
  exit 1
fi

# Ask for deletion confirmation if DELETE_ORIGINALS=1
if [ "$DELETE_ORIGINALS" -eq 1 ]; then
  read -rp "⚠️  Delete original files after conversion? (y/n) " confirm
  [[ "$confirm" != [Yy]* ]] && DELETE_ORIGINALS=0
fi

# Build find expression for extensions
find_expr=""
for ext in "${EXTENSIONS[@]}"; do
  if [ -n "$find_expr" ]; then
    find_expr="$find_expr -o"
  fi
  find_expr="$find_expr -iname *.${ext}"
done

echo "🔍 Searching for images in: $TARGET_DIR"

# Use process substitution instead of xargs for better handling of filenames with spaces
while IFS= read -r -d '' file; do
  # Skip if already a webp file
  [[ "$file" == *.webp ]] && continue

  out="${file%.*}.webp"

  # Skip if WebP already exists
  if [ -f "$out" ]; then
    echo "⚠️  Skipping (already exists): $(basename "$out")"
    continue
  fi

  echo "🔄 Converting: $(basename "$file")"

  # Handle HEIC files with best available method
  if [[ "$file" =~ \.(heic|HEIC)$ ]]; then
    if [ "$IMAGEMAGICK_HEIC" -eq 1 ]; then
      # Use ImageMagick directly if it has HEIC support
      if magick "$file" -quality "$QUALITY" -define webp:lossless=false -define webp:method=6 "$out" 2>/dev/null; then
        conversion_success=1
      else
        conversion_success=0
      fi
    elif [ "$HEIF_CONVERT_AVAILABLE" -eq 1 ]; then
      # Fall back to heif-convert + ImageMagick
      temp_jpg="${file%.*}_temp.jpg"
      if heif-convert -q "$QUALITY" "$file" "$temp_jpg" 2>/dev/null; then
        if magick "$temp_jpg" -quality "$QUALITY" "$out" 2>/dev/null; then
          rm "$temp_jpg" 2>/dev/null
          conversion_success=1
        else
          rm "$temp_jpg" 2>/dev/null
          conversion_success=0
        fi
      else
        conversion_success=0
      fi
    else
      # No HEIC support available, try ImageMagick anyway (will likely fail)
      if magick "$file" -quality "$QUALITY" "$out" 2>/dev/null; then
        conversion_success=1
      else
        conversion_success=0
      fi
    fi
  else
    # Use ImageMagick for all other formats
    if magick "$file" -quality "$QUALITY" "$out" 2>/dev/null; then
      conversion_success=1
    else
      conversion_success=0
    fi
  fi

  # Check conversion result
  if [ "$conversion_success" -eq 1 ]; then
    echo "✅ Converted: $(basename "$file") → $(basename "$out")"

    # Delete original if requested
    if [ "$DELETE_ORIGINALS" -eq 1 ]; then
      if rm "$file"; then
        echo "🗑️  Deleted original: $(basename "$file")"
      else
        echo "❌ Failed to delete: $(basename "$file")" >&2
      fi
    fi
  else
    echo "❌ Failed to convert: $(basename "$file")" >&2
    # Provide specific guidance for HEIC files
    if [[ "$file" =~ \.(heic|HEIC)$ ]]; then
      if [ "$IMAGEMAGICK_HEIC" -eq 0 ] && [ "$HEIF_CONVERT_AVAILABLE" -eq 0 ]; then
        echo "   💡 No HEIC support found. Install: sudo dnf install libheif-tools"
      fi
    fi
  fi

done < <(find "$TARGET_DIR" -type f \( $find_expr \) -print0)

echo "🎉 Conversion complete!"
