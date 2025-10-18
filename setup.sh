#!/usr/bin/env bash

set -e

INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/dir_history"
BASHRC="$HOME/.bashrc"
PAST_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAST_SCRIPT_SRC="$PAST_SCRIPT_DIR/past.sh"
PAST_SCRIPT_DEST="$INSTALL_DIR/past"

echo "📦 Installing past..."

# Ensure install and config directories exist
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# Copy the main script
cp "$PAST_SCRIPT_SRC" "$PAST_SCRIPT_DEST"
chmod +x "$PAST_SCRIPT_DEST"

echo "✅ Installed past to $PAST_SCRIPT_DEST"

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo "🔧 Adding ~/.local/bin to PATH in $BASHRC..."
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
fi

# Add or update Bash wrapper
if grep -q "past()" "$BASHRC"; then
  echo "🔁 Updating existing past() wrapper in $BASHRC..."
  # Remove the old function definition
  sed -i '/past() {/,/^}/d' "$BASHRC"
fi

echo "🪄 Adding new past() wrapper to $BASHRC..."
cat >> "$BASHRC" <<'EOF'

# Wrapper for past — allows directory switching
past() {
    local target
    target=$("$HOME/.local/bin/past" "$@")
    if [[ -n "\$target" && -d "\$target" ]]; then
        cd "\$target" || echo "Failed to cd to \$target"
    fi
}
EOF

echo "✅ past() wrapper added to $BASHRC"

echo "🎉 Installation complete!"
echo ""
echo "👉 Run the following command to apply changes immediately:"
echo "   exec bash"
echo ""
echo "Then start using:"
echo "   past"
echo ""
echo "Use 'past --fav' to manage your favorite directories."
