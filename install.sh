#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOME="$HOME"

echo "◆ Installing Umbralia dotfiles..."

# --- User config (home/kuro/... -> ~/...) ---
echo "[1/3] Copying user config files..."
cp -r "$DOTFILES_DIR/home/kuro/.config/." "$TARGET_HOME/.config/"
cp -r "$DOTFILES_DIR/home/kuro/.local/." "$TARGET_HOME/.local/"

# --- System files (needs sudo) ---
echo "[2/3] Copying system config (requires sudo)..."
sudo cp -r "$DOTFILES_DIR/etc/." /etc/
sudo cp -r "$DOTFILES_DIR/usr/share/umbriel/." /usr/share/umbriel/

# --- Fonts (optional: refresh cache) ---
echo "[3/3] Refreshing font cache..."
fc-cache -f "$TARGET_HOME/.local/share/fonts"

echo "✔ Install complete. You may need to log out/in or restart affected services."
