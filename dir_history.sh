# Config directory for all history files and temps
DIR_HISTORY_CONFIG_DIR="$HOME/.config/dir_history"
mkdir -p "$DIR_HISTORY_CONFIG_DIR"

# Files for history and favorites
export DIR_HISTORY_FILE="$DIR_HISTORY_CONFIG_DIR/dir_history"
export DIR_HISTORY_SIZE=10

FAV_HISTORY_FILE="$DIR_HISTORY_CONFIG_DIR/dir_favorites"
FAV_HISTORY_SIZE=10

# Color codes
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_UNDERLINE="\033[4m"
COLOR_CYAN="\033[36m"
COLOR_YELLOW="\033[33m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"

# Truncate string to fit width, adding "..." in the middle
truncate_middle() {
    local input="$1"
    local maxlen="$2"
    local len=${#input}
    if (( len <= maxlen )); then
        echo "$input"
    else
        local half=$(( (maxlen - 3) / 2 ))
        echo "${input:0:half}...${input: -half}"
    fi
}

track_dir_history() {
    [ "$PWD" != "$_LAST_DIR" ] || return
    _LAST_DIR="$PWD"

    local tmpfile
    tmpfile=$(mktemp "$DIR_HISTORY_CONFIG_DIR/tmp.XXXXXX") || return

    {
        echo "$PWD"
        grep -vFx "$PWD" "$DIR_HISTORY_FILE" 2>/dev/null
    } | head -n "$DIR_HISTORY_SIZE" | tee "$tmpfile" > /dev/null

    command mv -f "$tmpfile" "$DIR_HISTORY_FILE"
}

# Hook track_dir_history into PROMPT_COMMAND
if [[ $PROMPT_COMMAND != *track_dir_history* ]]; then
    PROMPT_COMMAND="track_dir_history${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

past() {
    mkdir -p "$DIR_HISTORY_CONFIG_DIR"
    touch "$DIR_HISTORY_FILE" "$FAV_HISTORY_FILE"

    if [[ "$1" == "-help" ]]; then
        echo -e "${COLOR_BOLD}Usage:${COLOR_RESET} past [command] [number]"
        echo -e ""
        echo -e "${COLOR_CYAN}Commands:${COLOR_RESET}"
        echo -e "  ${COLOR_YELLOW}past${COLOR_RESET}               Show past and favorite directories side-by-side"
        echo -e "  ${COLOR_YELLOW}past N${COLOR_RESET}             Change directory to past entry number N"
        echo -e "  ${COLOR_YELLOW}past fav N${COLOR_RESET}         Change directory to favorite entry number N"
        echo -e "  ${COLOR_YELLOW}past -fav N${COLOR_RESET}        Add past entry number N to favorites"
        echo -e "  ${COLOR_YELLOW}past -ufav N${COLOR_RESET}       Remove favorite entry number N from favorites"
        echo -e "  ${COLOR_YELLOW}past -help${COLOR_RESET}         Show this help message"
        return
    fi

    if [[ "$1" == "-fav" && "$2" =~ ^[0-9]+$ ]]; then
        local index="$2"
        local line
        line=$(sed -n "${index}p" "$DIR_HISTORY_FILE" 2>/dev/null)
        if [ -n "$line" ]; then
            grep -vFx "$line" "$FAV_HISTORY_FILE" > "$DIR_HISTORY_CONFIG_DIR/fav_tmp"
            { echo "$line"; cat "$DIR_HISTORY_CONFIG_DIR/fav_tmp"; } | head -n "$FAV_HISTORY_SIZE" | tee "$DIR_HISTORY_CONFIG_DIR/fav_tmp2" > /dev/null
            command mv -f "$DIR_HISTORY_CONFIG_DIR/fav_tmp2" "$FAV_HISTORY_FILE"
            rm -f "$DIR_HISTORY_CONFIG_DIR/fav_tmp"
            echo -e "${COLOR_GREEN}Added to favorites:${COLOR_RESET} $line"
        else
            echo -e "${COLOR_RED}No such entry in past:${COLOR_RESET} $index"
        fi
        return
    elif [[ "$1" == "-ufav" && "$2" =~ ^[0-9]+$ ]]; then
        local index="$2"
        local favline
        favline=$(sed -n "${index}p" "$FAV_HISTORY_FILE" 2>/dev/null)
        if [ -n "$favline" ]; then
            grep -vFx "$favline" "$FAV_HISTORY_FILE" | tee "$DIR_HISTORY_CONFIG_DIR/fav_tmp" > /dev/null
            command mv -f "$DIR_HISTORY_CONFIG_DIR/fav_tmp" "$FAV_HISTORY_FILE"
            echo -e "${COLOR_GREEN}Removed from favorites:${COLOR_RESET} $favline"
        else
            echo -e "${COLOR_RED}No such favorite entry:${COLOR_RESET} $index"
        fi
        return
    elif [[ "$1" == "fav" && "$2" =~ ^[0-9]+$ ]]; then
        local favline
        favline=$(sed -n "${2}p" "$FAV_HISTORY_FILE" 2>/dev/null)
        if [ -n "$favline" ]; then
            cd "$favline" || echo -e "${COLOR_RED}Failed to cd to:${COLOR_RESET} $favline"
        else
            echo -e "${COLOR_RED}No such favorite entry:${COLOR_RESET} $2"
        fi
        return
    elif [[ "$1" =~ ^[0-9]+$ ]]; then
        local line
        line=$(sed -n "${1}p" "$DIR_HISTORY_FILE" 2>/dev/null)
        if [ -n "$line" ]; then
            cd "$line" || echo -e "${COLOR_RED}Failed to cd to:${COLOR_RESET} $line"
        else
            echo -e "${COLOR_RED}No such entry:${COLOR_RESET} $1"
        fi
        return
    fi

    # Show table
    mapfile -t past_lines < <(nl -w2 -s': ' "$DIR_HISTORY_FILE")
    mapfile -t fav_lines  < <(nl -w2 -s': ' "$FAV_HISTORY_FILE")

    term_width=$(tput cols)
    ((term_width < 40)) && term_width=80  # Fallback
    col_width=$(( (term_width - 3) / 2 )) # 3 for " | "

    printf "${COLOR_BOLD}${COLOR_UNDERLINE}%-*s${COLOR_RESET} | ${COLOR_BOLD}${COLOR_UNDERLINE}%s${COLOR_RESET}\n" \
        "$col_width" "Past Directories:" "Favorite Directories:"
    printf '%*s-+-%*s\n' "$col_width" '' "$col_width" '' | tr ' ' '-'

    max_lines=${#past_lines[@]}
    (( ${#fav_lines[@]} > max_lines )) && max_lines=${#fav_lines[@]}

    for ((i = 0; i < max_lines; i++)); do
        past="${past_lines[i]}"
        fav="${fav_lines[i]}"
        past_display=$(truncate_middle "$past" "$col_width")
        fav_display=$(truncate_middle "$fav" "$col_width")
        printf "${COLOR_CYAN}%-*s${COLOR_RESET} | ${COLOR_YELLOW}%-*s${COLOR_RESET}\n" \
            "$col_width" "$past_display" "$col_width" "$fav_display"
    done
}
