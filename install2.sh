#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  U M B R A L I A   —   dotfiles & system installer
# ══════════════════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Color palette (respects NO_COLOR / non-tty) ──────────────
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  B=$'\033[1m'
  R=$'\033[0m'
  GREEN=$'\033[38;5;71m'
  YELLOW=$'\033[38;5;178m'
  RED=$'\033[38;5;167m'
  BLUE=$'\033[38;5;110m'
  GRAY=$'\033[38;5;244m'
else
  B='' R='' GREEN='' YELLOW='' RED='' BLUE='' GRAY=''
fi

# ── Printers ─────────────────────────────────────────────────
line() { printf "${GRAY}%s${R}\n" "────────────────────────────────────────────────────────────"; }
info() { printf "  ${BLUE}[INFO]${R}  %s\n" "$1"; }
ok()   { printf "  ${GREEN}[ OK ]${R}  %s\n" "$1"; }
warn() { printf "  ${YELLOW}[WARN]${R}  %s\n" "$1"; }
err()  { printf "  ${RED}[FAIL]${R}  %s\n" "$1" >&2; }

step() {
  local n="$1" total="$2" title="$3"
  printf "\n${B}[%d/%d]${R} ${B}%s${R}\n" "$n" "$total" "$title"
  line
}

die() {
  err "$1"
  exit 1
}

# ── Pre-flight checks ─────────────────────────────────────────
printf "\n${B}UMBRALIA${R} ${GRAY}—${R} dotfiles & system installer\n"
line

[[ $EUID -eq 0 ]] && die "Do NOT run as root — run as your normal user."
command -v pacman &>/dev/null || die "This script targets Arch Linux (pacman not found)."
curl -fsI --max-time 5 https://archlinux.org >/dev/null || die "No network connection detected."

# Cache sudo once and keep it alive for the whole script
sudo -v
(while true; do sudo -nv; sleep 55; done) &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT

# ─────────────────────────────────────────────────────────────
step 1 8 "Dotfiles → home"
cp -r "$DOTFILES_DIR/home/kuro/.config/." "$HOME/.config/"
cp -r "$DOTFILES_DIR/home/kuro/.local/." "$HOME/.local/"
ok "user configs in place"

# ─────────────────────────────────────────────────────────────
step 2 8 "System config → /etc"
sudo cp -r "$DOTFILES_DIR/etc/." /etc/
ok "/etc merged"

# Hybrid laptop (Ryzen 5500U iGPU + GTX 1650): let the idle dGPU sleep
echo 'ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/control}="auto"' \
  | sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null
ok "NVIDIA power rule installed"

fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
ok "font cache refreshed"

# ─────────────────────────────────────────────────────────────
step 3 8 "Official packages"
UCODE="amd-ucode"
grep -q GenuineIntel /proc/cpuinfo && UCODE="intel-ucode"

sudo pacman -Syu --needed --noconfirm \
  "$UCODE" \
  adw-gtk-theme base-devel ffmpegthumbnailer foot gthumb gvfs gvfs-mtp libva-mesa-driver loupe mesa mpv neovim noctalia ntfs-3g obsidian openssh starship thunar-archive-plugin thunar-volman tumbler udisks2 unzip vulkan-radeon xarchiver zed zsh zsh-autosuggestions zsh-syntax-highlighting
ok "pacman packages installed"

# ─────────────────────────────────────────────────────────────
step 4 8 "yay (AUR helper)"
if command -v yay &>/dev/null; then
  info "yay already installed — skipping"
else
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"; kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT
  git clone --quiet https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (cd "$tmpdir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmpdir" "$HOME/.cache/go"
  if pacman -Qi go &>/dev/null &&
    [[ "$(pacman -Qi go | awk -F': ' '/Install Reason/{print $2}')" == *"dependency"* ]]; then
    sudo pacman -Rns --noconfirm go
  fi
  ok "yay built & installed"
fi

# ─────────────────────────────────────────────────────────────
step 5 8 "AUR packages"
yay -S --needed --noconfirm \
  deckcraft-bin flow-browser-bin gridcraft-bin localsend-bin mpv-uosc-git noctalia-greeter qt6ct-kde rayburst-bin umbriel-git wordcraft-bin
ok "AUR packages installed"

# ─────────────────────────────────────────────────────────────
step 6 8 "Snapper tuning & services"
for cfg in /etc/snapper/configs/root /etc/snapper/configs/home; do
  if [[ -f "$cfg" ]]; then
    sudo sed -i \
      -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="4"/' \
      -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="0"/' \
      -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="3"/' \
      -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
      -e 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' \
      -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
      "$cfg"
    ok "tuned $(basename "$cfg")"
  else
    warn "$cfg not found — skipped"
  fi
done

sudo mkdir -p /etc/systemd/system/snapper-timeline.timer.d
sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf >/dev/null <<'EOF'
[Timer]
OnCalendar=
OnCalendar=00/6:00
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2 snapper-timeline.timer
sudo systemctl enable greetd
ok "services enabled"

# ─────────────────────────────────────────────────────────────
step 7 8 "Zsh as default shell"
if [[ ! -f /etc/zsh/zshenv ]] || ! grep -q 'ZDOTDIR' /etc/zsh/zshenv; then
  echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee -a /etc/zsh/zshenv >/dev/null
fi
sudo chsh -s /usr/bin/zsh "$USER"
ok "shell → zsh"

# ─────────────────────────────────────────────────────────────
step 8 8 "Done"
printf "\n${GREEN}${B}Installation complete.${R} Rebooting in 10s — press Ctrl+C to cancel.\n"
line
sleep 10
sudo reboot
