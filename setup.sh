#!/usr/bin/env bash
set -e

# === Paths ===
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/dir_history"
BASHRC="$HOME/.bashrc"
PAST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAST_SCRIPT_SRC="$PAST_SCRIPT_DIR/past.sh"
PAST_SCRIPT_DEST="$INSTALL_DIR/past"
TRACK_SCRIPT="$CONFIG_DIR/dir_history.sh"
HIST_FILE="$CONFIG_DIR/history.txt"

echo "📦 Installing past..."

# === Check for fzf ===
if ! command -v fzf >/dev/null 2>&1; then
  echo "🔍 'fzf' not found. Installing..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update -y && sudo apt install fzf -y
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install fzf -y
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy fzf --noconfirm
  elif command -v brew >/dev/null 2>&1; then
    brew install fzf
  else
    echo "❌ Unable to install 'fzf' automatically. Please install it manually and rerun setup."
    exit 1
  fi
  echo "✅ fzf installed successfully."
else
  echo "✅ fzf already installed."
fi

# === Create directories ===
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# === Install main 'past' script ===
if [[ ! -f "$PAST_SCRIPT_SRC" ]]; then
  echo "❌ Error: couldn't find '$PAST_SCRIPT_SRC'"
  echo "Make sure 'past.sh' is in the same directory as setup.sh"
  exit 1
fi

cp "$PAST_SCRIPT_SRC" "$PAST_SCRIPT_DEST"
chmod +x "$PAST_SCRIPT_DEST"
echo "✅ Installed 'past' to $PAST_SCRIPT_DEST"

# === Ensure ~/.local/bin in PATH ===
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "🔧 Adding ~/.local/bin to PATH in $BASHRC..."
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

# === Install directory tracker ===
echo "🧭 Setting up directory tracking..."
cat > "$TRACK_SCRIPT" <<'EOF'
#!/usr/bin/env bash

HIST_FILE="$HOME/.config/dir_history/history.txt"
mkdir -p "$(dirname "$HIST_FILE")"
touch "$HIST_FILE"

update_dir_history() {
    local new_dir="$PWD"

    # Skip unwanted paths
    [[ "$new_dir" =~ ^/tmp ]] && return
    [[ "$new_dir" =~ ^/proc ]] && return

    # Remove duplicates and prepend new dir
    grep -Fxv "$new_dir" "$HIST_FILE" > "${HIST_FILE}.tmp" 2>/dev/null || true
    echo "$new_dir" > "$HIST_FILE"
    cat "${HIST_FILE}.tmp" >> "$HIST_FILE"
    rm -f "${HIST_FILE}.tmp"

    # Keep only 100 entries
    head -n 100 "$HIST_FILE" > "${HIST_FILE}.tmp" && mv "${HIST_FILE}.tmp" "$HIST_FILE"
}

# Hook into cd command
cd() {
    builtin cd "$@" || return
    update_dir_history
}
EOF

chmod +x "$TRACK_SCRIPT"
echo "✅ Directory tracking script installed at $TRACK_SCRIPT"

# === Add or update Bash wrapper and tracker sourcing ===
if grep -q "past()" "$BASHRC"; then
  echo "🔁 Updating existing past() wrapper in $BASHRC..."
  sed -i '/past() {/,/^}/d' "$BASHRC"
fi

if ! grep -q "dir_history.sh" "$BASHRC"; then
  echo "🔧 Adding tracker sourcing to $BASHRC..."
  echo "[ -f \"$TRACK_SCRIPT\" ] && source \"$TRACK_SCRIPT\"" >> "$BASHRC"
fi

echo "🪄 Adding new past() wrapper to $BASHRC..."
cat >> "$BASHRC" <<'EOF'

# Wrapper for past — allows directory switching interactively
past() {
    local target
    target=$("$HOME/.local/bin/past" "$@")
    if [[ -n "$target" && -d "$target" ]]; then
        cd "$target" || echo "Failed to cd to $target"
    fi
}
EOF

echo "✅ Bash integration complete"

# === Final message ===
echo ""
echo "🎉 Installation complete!"
echo "👉 Run 'exec bash' to reload your shell, or restart your terminal."
echo ""
echo "Then start using:"
echo "   past"
echo ""
echo "Your directory history will now be tracked automatically."
