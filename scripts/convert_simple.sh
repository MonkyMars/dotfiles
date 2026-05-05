#!/bin/bash

input_file="$1"
output_file="${input_file%.*}_converted.mkv"

ffmpeg \
  -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i "$input_file" \
  -vf 'scale_vaapi=w=1920:h=-2' \
  -c:v h264_vaapi \
  -qp 20 \
  -c:a aac \
  -b:a 192k \
  -c:s copy \
  -map 0:v:0 \
  -map 0:a:0 \
  -map 0:s? \
  "$output_file"

echo "Done: $output_file"
