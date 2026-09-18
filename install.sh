#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOME="$HOME"

echo "◆ Umbralia dotfiles installer"
echo "──────────────────────────────────────────"

# Cache sudo upfront so later steps don't randomly prompt mid-script
sudo -v

# ─────────────────────────────────────────────
# 1. Copy dotfiles into place
# ─────────────────────────────────────────────
echo "[1/7] Copying user config files..."
cp -r "$DOTFILES_DIR/home/kuro/.config/." "$TARGET_HOME/.config/"
cp -r "$DOTFILES_DIR/home/kuro/.local/." "$TARGET_HOME/.local/"

echo "[2/7] Copying system config (requires sudo)..."
sudo cp -r "$DOTFILES_DIR/etc/." /etc/
sudo cp -r "$DOTFILES_DIR/usr/share/umbriel/." /usr/share/umbriel/

echo "Refreshing font cache..."
fc-cache -f "$TARGET_HOME/.local/share/fonts"

# ─────────────────────────────────────────────
# 2. Install official packages
# ─────────────────────────────────────────────
echo "[3/7] Syncing and installing official packages..."
sudo pacman -Syu --needed git zsh udisks2 starship zsh-autosuggestions \
    zsh-syntax-highlighting foot base-devel ntfs-3g gvfs gvfs-mtp \
    amd-ucode mpv gthumb tumbler ffmpegthumbnailer thunar-volman zed

# ─────────────────────────────────────────────
# 3. Install yay (must run as normal user, NOT root)
# ─────────────────────────────────────────────
echo "[4/7] Installing yay..."
if command -v yay &> /dev/null; then
    echo "  yay already installed, skipping."
else
    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    rm -rf ~/.cache/go
    sudo pacman -Rns --noconfirm go
fi

# ─────────────────────────────────────────────
# 4. Install AUR packages
# ─────────────────────────────────────────────
echo "[5/7] Installing AUR packages..."
yay -S --needed --noconfirm umbriel-git noctalia-greeter helium-browser-bin obsidian

# ─────────────────────────────────────────────
# 5. Configure snapper (tuning on top of archinstall defaults)
# ─────────────────────────────────────────────
echo "[6/7] Configuring snapper..."
for cfg in /etc/snapper/configs/root /etc/snapper/configs/home; do
    if [ -f "$cfg" ]; then
        sudo sed -i \
            -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="4"/' \
            -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="0"/' \
            -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="3"/' \
            -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
            -e 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' \
            -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
            "$cfg"
    else
        echo "  Warning: $cfg not found, skipping."
    fi
done

sudo mkdir -p /etc/systemd/system/snapper-timeline.timer.d
sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf > /dev/null << 'EOF'
[Timer]
OnCalendar=
OnCalendar=00/6:00
EOF

sudo systemctl daemon-reload
sudo systemctl restart snapper-timeline.timer

# ─────────────────────────────────────────────
# 6. Enable services
# ─────────────────────────────────────────────
echo "[7/7] Enabling services..."
sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2 greetd

# ─────────────────────────────────────────────
# 7. Switch shell to zsh (last, needs reboot/relogin anyway)
# ─────────────────────────────────────────────
echo "Switching default shell to zsh..."
echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee /etc/zsh/zshenv > /dev/null
chsh -s /usr/bin/zsh

echo ""
echo "✔ Install complete."
echo "A reboot is required for all changes to take effect (shell, greeter, services)."
read -p "Press enter to reboot now, or Ctrl+C to cancel and reboot later..."
sudo reboot
