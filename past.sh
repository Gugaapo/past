#!/usr/bin/env bash

# ==========================================================
#  past - Simple TUI directory history & favorites manager
# ==========================================================

# --- Configuration ---
DIR_HISTORY_CONFIG_DIR="$HOME/.config/dir_history"
mkdir -p "$DIR_HISTORY_CONFIG_DIR"
DIR_HISTORY_FILE="$DIR_HISTORY_CONFIG_DIR/history.txt"
FAV_HISTORY_FILE="$DIR_HISTORY_CONFIG_DIR/dir_favorites"
DIR_HISTORY_SIZE=10
FAV_HISTORY_SIZE=10

# --- Color Definitions ---
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
BLUE="\033[34m"
CYAN="\033[36m"
YELLOW="\033[33m"
GREEN="\033[32m"
GRAY="\033[90m"
INVERT="\033[7m"

# --- Helpers ---
truncate_middle() {
    local input="$1" maxlen="$2" len=${#input}
    (( len <= maxlen )) && echo "$input" && return
    local half=$(( (maxlen - 3) / 2 ))
    echo "${input:0:half}...${input: -half}"
}

add_to_favorites() {
    local dir="$1"
    grep -vFx "$dir" "$FAV_HISTORY_FILE" > "$FAV_HISTORY_FILE.tmp"
    { echo "$dir"; cat "$FAV_HISTORY_FILE.tmp"; } | head -n "$FAV_HISTORY_SIZE" > "$FAV_HISTORY_FILE"
    rm -f "$FAV_HISTORY_FILE.tmp"
    echo -e "${GREEN}★ Added to favorites:${RESET} $dir" >&2
    sleep 0.5
}

draw_menu() {
    local -n list=$1
    local selected=$2
    local header=$3

    clear >&2
    echo -e "${BOLD}${BLUE}$header${RESET}" >&2
    echo -e "${DIM}↑/↓ or number: navigate • Enter: open • Shift+Enter: favorite • Esc/q: quit${RESET}" >&2
    echo >&2

    for i in "${!list[@]}"; do
        local display
        display=$(truncate_middle "${list[i]}" "$(tput cols)")
        if [[ $i -eq $selected ]]; then
            echo -e "${INVERT}${YELLOW}$((i+1)). ${display}${RESET}" >&2
        else
            echo -e " ${CYAN}$((i+1)).${RESET} ${display}" >&2
        fi
    done
}

highlight_and_confirm() {
    local -n list=$1
    local index=$2
    local header=$3

    clear >&2
    echo -e "${BOLD}${BLUE}$header${RESET}" >&2
    echo -e "${DIM}Confirming selection...${RESET}" >&2
    echo >&2

    for i in "${!list[@]}"; do
        local display
        display=$(truncate_middle "${list[i]}" "$(tput cols)")
        if [[ $i -eq $index ]]; then
            echo -e "${INVERT}${YELLOW}$((i+1)). ${display}${RESET}" >&2
        else
            echo -e " ${CYAN}$((i+1)).${RESET} ${display}" >&2
        fi
    done
    sleep 0.2
}

# --- Mode: Past ---
mode_past() {
    mapfile -t dirs < "$DIR_HISTORY_FILE"
    (( ${#dirs[@]} == 0 )) && { echo "No directory history found." >&2; return; }

    local selected=0 key
    tput civis >&2
    while true; do
        draw_menu dirs "$selected" "📂 Recent Directories"
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b') # Escape or arrows
                read -rsn2 -t 0.01 key2 || true
                case "$key2" in
                    '[A') ((selected--)); ((selected < 0)) && selected=$(( ${#dirs[@]} - 1 )) ;; # Up
                    '[B') ((selected++)); ((selected >= ${#dirs[@]} )) && selected=0 ;;          # Down
                    '')  tput cnorm >&2; clear >&2; return ;;                                    # ESC key quits
                esac ;;
            '')  # Enter
                tput cnorm >&2
                clear >&2
                echo "${dirs[selected]}"
                return ;;
            [0-9])
                local num=$((10#$key))
                (( num == 0 )) && num=10
                (( num >= 1 && num <= ${#dirs[@]} )) || continue
                highlight_and_confirm dirs "$((num-1))" "📂 Recent Directories"
                tput cnorm >&2
                clear >&2
                echo "${dirs[num-1]}"
                return ;;
            $'\x0a')  # Shift+Enter (depends on terminal)
                add_to_favorites "${dirs[selected]}"
                ;;
            q) tput cnorm >&2; clear >&2; return ;;
        esac
    done
}

# --- Mode: Favorites ---
mode_fav() {
    mapfile -t favs < "$FAV_HISTORY_FILE"
    local options=("➕ Add current directory to favorites" "${favs[@]}")
    local selected=0 key
    tput civis >&2
    while true; do
        draw_menu options "$selected" "⭐ Favorite Directories"
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.01 key2 || true
                case "$key2" in
                    '[A') ((selected--)); ((selected < 0)) && selected=$(( ${#options[@]} - 1 )) ;;
                    '[B') ((selected++)); ((selected >= ${#options[@]} )) && selected=0 ;;
                    '')  tput cnorm >&2; clear >&2; return ;;  # ESC quits
                esac ;;
            '')  # Enter
                tput cnorm >&2
                clear >&2
                if (( selected == 0 )); then
                    add_to_favorites "$PWD"
                else
                    echo "${favs[selected-1]}"
                    return
                fi ;;
            [0-9])
                local num=$((10#$key))
                (( num == 0 )) && num=10
                (( num >= 1 && num <= ${#options[@]}-1 )) || continue
                highlight_and_confirm favs "$((num-1))" "⭐ Favorite Directories"
                tput cnorm >&2
                clear >&2
                echo "${favs[num-1]}"
                return ;;
            q) tput cnorm >&2; clear >&2; return ;;
        esac
    done
}

# --- Entry point ---
case "$1" in
    --fav) mode_fav ;;
    *) mode_past ;;
esac
