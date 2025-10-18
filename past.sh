#!/usr/bin/env bash
# past - Simple directory history and favorites manager (TUI version)
# Author: Gustavo
# License: MIT

set -e

# Config directory
DIR_HISTORY_CONFIG_DIR="$HOME/.config/dir_history"
mkdir -p "$DIR_HISTORY_CONFIG_DIR"

DIR_HISTORY_FILE="$DIR_HISTORY_CONFIG_DIR/dir_history"
DIR_HISTORY_SIZE=50
FAV_HISTORY_FILE="$DIR_HISTORY_CONFIG_DIR/dir_favorites"
FAV_HISTORY_SIZE=50

# --- Record current directory when called in shell prompt ---
track_dir_history() {
    [ "$PWD" != "$_LAST_DIR" ] || return
    _LAST_DIR="$PWD"

    tmpfile=$(mktemp "$DIR_HISTORY_CONFIG_DIR/tmp.XXXXXX")
    {
        echo "$PWD"
        grep -vFx "$PWD" "$DIR_HISTORY_FILE" 2>/dev/null
    } | head -n "$DIR_HISTORY_SIZE" > "$tmpfile"

    mv -f "$tmpfile" "$DIR_HISTORY_FILE"
}

# Hook into shell PROMPT_COMMAND if not yet hooked
if [[ $PROMPT_COMMAND != *track_dir_history* ]]; then
    PROMPT_COMMAND="track_dir_history${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

# --- Helper functions ---
add_to_favorites() {
    local dir="$1"
    grep -vFx "$dir" "$FAV_HISTORY_FILE" > "$DIR_HISTORY_CONFIG_DIR/tmp_fav"
    { echo "$dir"; cat "$DIR_HISTORY_CONFIG_DIR/tmp_fav"; } | head -n "$FAV_HISTORY_SIZE" > "$DIR_HISTORY_CONFIG_DIR/tmp_fav2"
    mv -f "$DIR_HISTORY_CONFIG_DIR/tmp_fav2" "$FAV_HISTORY_FILE"
    rm -f "$DIR_HISTORY_CONFIG_DIR/tmp_fav"
    echo "⭐ Added to favorites: $dir"
}

remove_from_favorites() {
    local dir="$1"
    grep -vFx "$dir" "$FAV_HISTORY_FILE" > "$DIR_HISTORY_CONFIG_DIR/tmp_fav"
    mv -f "$DIR_HISTORY_CONFIG_DIR/tmp_fav" "$FAV_HISTORY_FILE"
    echo "❌ Removed from favorites: $dir"
}

# --- Interactive Menu (TUI) ---
show_menu() {
    mkdir -p "$DIR_HISTORY_CONFIG_DIR"
    touch "$DIR_HISTORY_FILE" "$FAV_HISTORY_FILE"

    local choices=()
    choices+=("🕘 View past directories")
    choices+=("⭐ View favorite directories")
    choices+=("➕ Add current dir to favorites")
    choices+=("🧹 Clear history")
    choices+=("🚪 Exit")

    local selected
    selected=$(printf "%s\n" "${choices[@]}" | fzf --prompt="Select an action > " --height=15 --reverse)

    case "$selected" in
        "🕘 View past directories")
            select_from_list "$DIR_HISTORY_FILE" "past"
            ;;
        "⭐ View favorite directories")
            select_from_list "$FAV_HISTORY_FILE" "fav"
            ;;
        "➕ Add current dir to favorites")
            add_to_favorites "$PWD"
            ;;
        "🧹 Clear history")
            > "$DIR_HISTORY_FILE"
            echo "History cleared."
            ;;
        *)
            exit 0
            ;;
    esac
}

select_from_list() {
    local file="$1"
    local type="$2"
    [ -s "$file" ] || { echo "No entries yet."; return; }

    local dir
    dir=$(cat "$file" | fzf --prompt="Choose directory > " --height=15 --reverse)

    [ -z "$dir" ] && return

    echo "📁 $dir"
    echo

    local action
    action=$(printf "cd into\nadd to favorites\nremove from favorites\nback\n" | fzf --prompt="Action > " --height=10 --reverse)

    case "$action" in
        "cd into")
            echo "cd \"$dir\""
            ;;
        "add to favorites")
            add_to_favorites "$dir"
            ;;
        "remove from favorites")
            remove_from_favorites "$dir"
            ;;
        *)
            ;;
    esac
}

# --- Entry point ---
show_menu
