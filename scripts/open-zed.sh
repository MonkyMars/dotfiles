#!/usr/bin/env bash

set -euo pipefail

# Configuration
readonly HISTORY_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/zed-recent-paths"
readonly LOG_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/zed-open.log"
readonly MAX_HISTORY=50
readonly DEFAULT_QUERY="~/Coding"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Ensure history file exists
initialize_history() {
    mkdir -p "$(dirname "$HISTORY_FILE")"
    touch "$HISTORY_FILE"
    touch "$LOG_FILE"
}

add_to_history() {
    local path="$1"
    local tmp
    tmp=$(mktemp)

    # Remove existing entry and add to top
    grep -vFx "$path" "$HISTORY_FILE" 2>/dev/null > "$tmp" || true
    {
        echo "$path"
        head -n $((MAX_HISTORY - 1)) "$tmp"
    } > "$HISTORY_FILE"

    rm -f "$tmp"
}

resolve_path() {
    local input="$1"

    # Expand tilde
    input="${input/#\~/$HOME}"

    # Return realpath if exists, otherwise return as-is
    if [[ -e "$input" ]]; then
        realpath "$input"
    else
        echo "$input"
    fi
}

prettify_path() {
    sed "s|^$HOME|~|"
}

generate_completions() {
    local query="$1"
    local expanded="${query/#\~/$HOME}"

    # If empty query, show history
    if [[ -z "$query" ]]; then
        cat "$HISTORY_FILE" 2>/dev/null | prettify_path
        return
    fi

    {
        # Show matching history entries
        grep -iF "$query" "$HISTORY_FILE" 2>/dev/null | prettify_path || true

        # Directory completion
        if [[ -d "$expanded" ]]; then
            # If query ends with /, list directory contents
            if [[ "$query" == */ ]]; then
                find "$expanded" -maxdepth 1 \( -type f -o -type d \) 2>/dev/null
            else
                # Otherwise, find matching items in parent directory
                local dir="${expanded%/*}"
                local base="${expanded##*/}"
                [[ -d "$dir" ]] && find "$dir" -maxdepth 1 \( -type f -o -type d \) -iname "${base}*" 2>/dev/null || true
            fi
        else
            # Partial path completion
            local dir="${expanded%/*}"
            local base="${expanded##*/}"

            if [[ "$dir" != "$expanded" && -d "$dir" ]]; then
                find "$dir" -maxdepth 1 \( -type f -o -type d \) -iname "${base}*" 2>/dev/null || true
            else
                find "$HOME" -maxdepth 1 \( -type f -o -type d \) -iname "${base}*" 2>/dev/null || true
            fi
        fi
    } | awk '!seen[$0]++' | prettify_path
}

preview_path() {
    local target="${1/#\~/$HOME}"

    if [[ -d "$target" ]]; then
        ls -lAh --color=always "$target" 2>/dev/null || echo "Cannot preview directory"
    elif [[ -f "$target" ]]; then
        echo "File: $(file -b "$target")"
        echo "Size: $(du -h "$target" | cut -f1)"
        echo
        head -n 50 "$target" 2>/dev/null || echo "Cannot preview file"
    else
        echo "Path does not exist"
    fi
}

add_trailing_slash() {
    local path="$1"
    local expanded="${path/#\~/$HOME}"

    if [[ -d "$expanded" && "$path" != */ ]]; then
        echo "$path/"
    else
        echo "$path"
    fi
}

main() {
    initialize_history

    # Create temporary scripts for fzf callbacks
    local completion_script tab_script delete_script
    completion_script=$(mktemp)
    tab_script=$(mktemp)
    delete_script=$(mktemp)

    trap 'rm -f "$completion_script" "$tab_script" "$delete_script"' EXIT

    # Completion script
    cat > "$completion_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
generate_completions() {
    local query="$1"
    local expanded="${query/#\~/$HOME}"

    if [[ -z "$query" ]]; then
        cat "$HISTORY_FILE" 2>/dev/null | sed "s|^$HOME|~|"
        return
    fi

    {
        grep -iF "$query" "$HISTORY_FILE" 2>/dev/null | sed "s|^$HOME|~|" || true

        if [[ -d "$expanded" ]]; then
            if [[ "$query" == */ ]]; then
                find "$expanded" -maxdepth 1 \( -type f -o -type d \) 2>/dev/null
            else
                local dir="${expanded%/*}"
                local base="${expanded##*/}"
                [[ -d "$dir" ]] && find "$dir" -maxdepth 1 \( -type f -o -type d \) -iname "${base}*" 2>/dev/null || true
            fi
        else
            local dir="${expanded%/*}"
            local base="${expanded##*/}"

            if [[ "$dir" != "$expanded" && -d "$dir" ]]; then
                find "$dir" -maxdepth 1 \( -type f -o -type d \) -iname "${base}*" 2>/dev/null || true
            else
                find "$HOME" -maxdepth 1 \( -type f -o -type d \) -iname "${base}*" 2>/dev/null || true
            fi
        fi
    } | awk '!seen[$0]++' | sed "s|^$HOME|~|"
}
generate_completions "$1"
EOF
    chmod +x "$completion_script"

    # Tab completion script
    cat > "$tab_script" <<'EOF'
#!/usr/bin/env bash
path="$1"
expanded="${path/#\~/$HOME}"
if [[ -d "$expanded" && "$path" != */ ]]; then
    echo "$path/"
else
    echo "$path"
fi
EOF
    chmod +x "$tab_script"

    # Delete script - converts ~ back to absolute path before deleting
    cat > "$delete_script" <<'EOF'
#!/usr/bin/env bash
path="$1"
expanded="${path/#\~/$HOME}"
tmp=$(mktemp)
grep -vFx "$expanded" "$HISTORY_FILE" > "$tmp" 2>/dev/null || true
mv "$tmp" "$HISTORY_FILE"
cat "$HISTORY_FILE" | sed "s|^$HOME|~|"
EOF
    chmod +x "$delete_script"

    # Export variables for sub-scripts
    export HOME HISTORY_FILE

    # Run fzf
    local out query selection final
    out=$(
        cat "$HISTORY_FILE" 2>/dev/null | prettify_path |
        fzf \
            --disabled \
            --query="$DEFAULT_QUERY" \
            --prompt="Path > " \
            --header="Tab: complete | Enter: open | Ctrl-D: delete | Ctrl-/: preview" \
            --bind="change:reload:$completion_script {q}" \
            --bind="tab:transform:echo change-query(\$($tab_script {}))" \
            --bind="ctrl-d:reload:$delete_script {}" \
            --print-query \
            --select-1 \
            --exit-0 \
            --preview="$(declare -f preview_path); preview_path {}" \
            --preview-window=right:50%:wrap:hidden \
            --bind="ctrl-/:toggle-preview" \
            --height=60% \
            --reverse \
            --cycle
    ) || exit 0

    # Parse fzf output - handle both selection and query-only cases
    mapfile -t lines <<< "$out"

    query="${lines[0]}"
    selection="${lines[1]:-}"

    log "Query: '$query'"
    log "Selection: '$selection'"
    echo "Selected path: ${selection:-$query}" >&2

    # Use selection if available, otherwise use query
    final="${selection:-$query}"

    # If final is empty, user cancelled - exit cleanly
    if [[ -z "$final" ]]; then
        log "No selection or query, user cancelled"
        exit 0
    fi

    log "Final path before resolve: '$final'"

    # Resolve and validate path
    final=$(resolve_path "$final")

    if [[ ! -e "$final" ]]; then
        log "ERROR: Path does not exist: $final"
        echo "ERROR: Path does not exist: $final" >&2
        echo "Press Enter to close..."
        read
        exit 1
    fi

    log "Resolved path: '$final'"

    # Add to history and launch
    add_to_history "$final"

    log "Launching Zed with path: '$final'"

    # Launch Zed - redirect stderr to log file
    if gtk-launch dev.zed.Zed "$final" 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
        log "Zed launched successfully"
    else
        local exit_code=$?
        log "ERROR: Failed to launch Zed (exit code: $exit_code)"
        echo "ERROR: Failed to launch Zed" >&2
        echo "Check log file: $LOG_FILE" >&2
        echo "Press Enter to close..."
        read
        exit 1
    fi
}

main "$@"
