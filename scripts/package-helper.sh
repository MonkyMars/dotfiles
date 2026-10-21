#!/usr/bin/env bash
set -euo pipefail

helper=$(command -v paru || command -v yay) || {
  echo "paru or yay is required" >&2
  exit 1
}

"$helper" -Slq \
  | fzf --multi --ansi \
        --prompt 'install> ' \
        --preview "$helper -Si {1}" \
        --preview-window 'right:60%:wrap' \
        --bind 'ctrl-/:toggle-preview' \
  | xargs -ro "$helper" -S
