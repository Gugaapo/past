#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="past"
SOURCE_FILE="$(pwd)/past.sh"

mkdir -p "$INSTALL_DIR"
cp "$SOURCE_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo "✅ Installed $SCRIPT_NAME to $INSTALL_DIR"
echo "Make sure $HOME/.local/bin is in your PATH"
echo
echo "👉 To start: type 'past'"
