#!/bin/bash

# Video Conversion Script with VAAPI, 4-job parallelism, and live job ID progress
# Usage: ./convert_to_8bit.sh <input_folder> <output_folder>

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <input_folder> <output_folder>"
  exit 1
fi

INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"
MAX_JOBS=2
LOG_INTERVAL=5s

mkdir -p "$OUTPUT_FOLDER"

# Find video files
mapfile -d '' video_files < <(find "$INPUT_FOLDER" -type f \( -iname "*.mp4" -o -iname "*.mkv" \) -print0)

if [ ${#video_files[@]} -eq 0 ]; then
  echo "No MP4 or MKV files found in $INPUT_FOLDER"
  exit 1
fi

echo "Found ${#video_files[@]} file(s) to convert."
echo "Hardware acceleration: VAAPI (/dev/dri/renderD128)"
echo ""

convert_file() {
  local job_id="$1"
  local input_file="$2"
  local output_folder="$3"

  filename=$(basename "$input_file")
  name_without_ext="${filename%.*}"
  extension="${filename##*.}"
  output_file="$output_folder/${name_without_ext}.8bit.${extension}"

  if [ -f "$output_file" ]; then
    echo "[$job_id] ⚠️  Output exists, skipping: $filename"
    return
  fi

  echo "[$job_id] Starting conversion: $filename → $(basename "$output_file")"

  ffmpeg -hwaccel vaapi -vaapi_device /dev/dri/renderD128 \
    -i "$input_file" \
    -vf 'format=nv12,hwupload' \
    -c:v h264_vaapi \
    -qp 22 \
    -bf 0 \
    -g 120 \
    -profile:v high \
    -level 4.1 \
    -rc vbr \
    -b:v 6M -maxrate 10M -bufsize 12M \
    -c:a copy \
    -c:s copy \
    -y "$output_file" \
    -progress pipe:1 2>&1 | awk -v prefix="[$job_id]" -v interval=$LOG_INTERVAL '
BEGIN { last_time = systime(); frame=""; fps=""; time_val=""; bitrate="" }
/^[a-zA-Z_]+=.*$/ {
    split($0,a,"=")
    key=a[1]; val=a[2]
    if(key=="frame") frame=val
    if(key=="fps") fps=val
    if(key=="time") time_val=val
    if(key=="bitrate") bitrate=val
    if(key=="progress" && val=="continue") {
        now = systime()
        if(now - last_time >= interval) {
            timestamp = strftime("%H:%M:%S", now)
            printf "%s [%s] frame=%s fps=%s time=%s bitrate=%s\n", prefix, timestamp, frame, fps, time_val, bitrate
            last_time = now
        }
    }
}'

  echo "[$job_id] Conversion finished: $filename"
}

# Counter for progress tracking
count=0
total=${#video_files[@]}

# Parallel processing loop
for input_file in "${video_files[@]}"; do
  count=$((count + 1))
  job_id="$count"
  echo "[$job_id/$total] Scheduling: $(basename "$input_file")"

  convert_file "$job_id" "$input_file" "$OUTPUT_FOLDER" &

  # Limit to MAX_JOBS running at the same time
  while [ "$(jobs -rp | wc -l)" -ge "$MAX_JOBS" ]; do
    sleep 1
  done
done

# Wait for all jobs to finish
wait
echo "All conversions completed!"
