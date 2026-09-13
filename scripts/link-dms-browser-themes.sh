#!/usr/bin/env bash
set -euo pipefail

dms_config="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
firefox_css="$dms_config/firefox.css"
zen_css="$dms_config/zen.css"

link_profile() {
    local profile_dir="$1"
    local source="$2"
    local target="$3"

    [[ -f "$source" ]] || return 0
    mkdir -p "$profile_dir/chrome"
    ln -sfn "$source" "$profile_dir/chrome/$target"
    printf 'Linked %s -> %s\n' "$profile_dir/chrome/$target" "$source"
}

while IFS= read -r -d '' profile; do
    link_profile "$profile" "$firefox_css" "theme-material-blue.css"
done < <(
    find \
        "$HOME/.mozilla/firefox" \
        "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox" \
        -mindepth 1 -maxdepth 1 -type d -name '*.default-release' -print0 2>/dev/null
)

while IFS= read -r -d '' profile; do
    link_profile "$profile" "$zen_css" "userChrome.css"
done < <(
    find \
        "$HOME/.zen" \
        "$HOME/.config/zen" \
        "$HOME/.var/app/app.zen_browser.zen/.zen" \
        -mindepth 1 -maxdepth 1 -type d \( \
            -name '*.Default Profile' -o \
            -name '*.Default (release)' \
        \) -print0 2>/dev/null
)
