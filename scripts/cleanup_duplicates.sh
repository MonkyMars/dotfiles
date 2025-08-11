#!/bin/bash
# Remove original image files when WebP versions exist

# Extensions to check for originals
EXTENSIONS=("jpg" "jpeg" "png" "heic" "bmp" "tiff" "gif")

# Check argument
if [ -z "$1" ]; then
  echo "Usage: $0 /path/to/folder"
  echo "This will delete original files that have corresponding .webp versions"
  exit 1
fi

TARGET_DIR="$1"

# Validate target directory
if [ ! -d "$TARGET_DIR" ]; then
  echo "❌ Error: Directory '$TARGET_DIR' does not exist."
  exit 1
fi

# Safety confirmation
echo "🔍 This will look for original images that have .webp counterparts and DELETE the originals."
echo "📁 Target directory: $TARGET_DIR"
read -rp "⚠️  Continue? (y/n) " confirm
if [[ "$confirm" != [Yy]* ]]; then
  echo "❌ Cancelled."
  exit 0
fi

count=0
deleted=0

echo "🧹 Scanning for duplicates..."

# Find all non-webp image files
for ext in "${EXTENSIONS[@]}"; do
  while IFS= read -r -d '' original_file; do
    count=$((count + 1))

    # Generate expected WebP filename
    webp_file="${original_file%.*}.webp"

    # Check if WebP version exists
    if [ -f "$webp_file" ]; then
      echo "🗑️  Deleting: $(basename "$original_file") (WebP exists)"
      if rm "$original_file"; then
        deleted=$((deleted + 1))
      else
        echo "❌ Failed to delete: $(basename "$original_file")" >&2
      fi
    fi

  done < <(find "$TARGET_DIR" -type f -iname "*.${ext}" -print0)
done

echo ""
echo "✅ Cleanup complete!"
echo "📊 Processed: $count original files"
echo "🗑️  Deleted: $deleted duplicates"
echo "💾 Saved space by removing originals with WebP versions"
