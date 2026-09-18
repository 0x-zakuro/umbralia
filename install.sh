#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  U M B R A L I A   —   dotfiles & system installer
# ══════════════════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOME="$HOME"
BACKUP_DIR="$HOME/.umbralia-backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$HOME/umbralia-install.log"

# ── Color palette (respects NO_COLOR / non-tty) ──────────────
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    B='\033[1m';   D='\033[2m';   R='\033[0m'
    CYAN='\033[38;5;45m';  VIOLET='\033[38;5;141m'
    GREEN='\033[38;5;84m';  YELLOW='\033[38;5;221m'
    RED='\033[38;5;203m';   BLUE='\033[38;5;75m'
    GRAY='\033[38;5;240m'
else
    B=''; D=''; R=''; CYAN=''; VIOLET=''; GREEN=''; YELLOW=''; RED=''; BLUE=''; GRAY=''
fi

# ── Pretty printers ──────────────────────────────────────────
line()  { printf "${GRAY}%s${R}\\n" "──────────────────────────────────────────────────────────────"; }
hdr()   { printf "${CYAN}${B}  %s${R}\\n" "$1"; }
info()  { printf "  ${BLUE}▸${R}  %s\\n" "$1"; }
ok()    { printf "  ${GREEN}${B}✔${R}  %s\\n" "$1"; }
warn()  { printf "  ${YELLOW}${B}!${R}  %s\\n" "$1"; }
err()   { printf "  ${RED}${B}✖${R}  %s\\n" "$1" >&2; }

step() {  # step 3 9 "Official packages"
    local n="$1" total="$2" title="$3"
    printf "\\n${VIOLET}${B}──[${R} ${CYAN}${B}%d${R}${D}/${R}${CYAN}${B}%d${R} ${VIOLET}${B}]──${R}  ${B}%s${R}\\n" "$n" "$total" "$title"
    line
}

die() { err "$1"; exit 1; }

# ── Pre-flight checks ─────────────────────────────────────────
clear 2>/dev/null || true
printf "${CYAN}${B}"
printf "  ╔══════════════════════════════════════════════════════════╗\\n"
printf "  ║                                                          ║\\n"
printf "  ║        █ █ █ █ █  U M B R A L I A  █ █ █ █ █             ║\\n"
printf "  ║                                                          ║\\n"
printf "  ║        dotfiles · packages · services · shell            ║\\n"
printf "  ║                                                          ║\\n"
printf "  ╚══════════════════════════════════════════════════════════╝\\n"
printf "${R}\\n"
line
info "dotfiles : ${D}$DOTFILES_DIR${R}"
info "backups  : ${D}$BACKUP_DIR${R}"
info "log      : ${D}$LOG_FILE${R}"
line

[[ $EUID -eq 0 ]]           && die "Do NOT run as root — run as your normal user."
command -v pacman &>/dev/null || die "This script targets Arch Linux (pacman not found)."
ping -c1 -W3 archlinux.org &>/dev/null || die "No network connection detected."

mkdir -p "$BACKUP_DIR"; touch "$LOG_FILE"

# Cache sudo + keep it alive for the whole script
sudo -v
( while true; do sudo -nv; sleep 55; done ) &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT

backup() {
    local path="$1"
    if [[ -e "$path" ]]; then
        mkdir -p "$BACKUP_DIR$(dirname "$path")"
        cp -a "$path" "$BACKUP_DIR$path"
        info "${D}backed up →${R} $path"
    fi
}

# ─────────────────────────────────────────────────────────────
step 1 9 "Dotfiles → home"
backup "$TARGET_HOME/.config"
backup "$TARGET_HOME/.local"
cp -r "$DOTFILES_DIR/home/kuro/.config/." "$TARGET_HOME/.config/"
cp -r "$DOTFILES_DIR/home/kuro/.local/." "$TARGET_HOME/.local/"
ok "user configs in place"

# ─────────────────────────────────────────────────────────────
step 2 9 "System config → /etc"
sudo cp -r "$DOTFILES_DIR/etc/." /etc/
# NOTE: do NOT copy usr/share/umbriel here if umbriel-git (step 5)
# ships the same paths — pacman will refuse with "exists in filesystem".
# Pick ONE owner: either the package, or this copy.
ok "/etc merged"

info "refreshing font cache…"
fc-cache -f "$TARGET_HOME/.local/share/fonts" 2>/dev/null || true

# ─────────────────────────────────────────────────────────────
step 3 9 "Official packages"
UCODE="amd-ucode"
grep -q GenuineIntel /proc/cpuinfo && UCODE="intel-ucode"
info "microcode: $UCODE"

sudo pacman -Syu --needed --noconfirm \
    "$UCODE" \
    base-devel ffmpegthumbnailer foot git gnome-boxes gthumb gvfs gvfs-mtp \
    localsend mpv neovim noctalia ntfs-3g openssh starship \
    thunar-archive-plugin thunar-volman tumbler udisks2 zed zsh \
    zsh-autosuggestions zsh-syntax-highlighting
ok "pacman packages installed"

# ─────────────────────────────────────────────────────────────
step 4 9 "yay (AUR helper)"
if command -v yay &>/dev/null; then
    info "yay already installed — skipping"
else
    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"; kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT
    git clone --quiet https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (cd "$tmpdir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    rm -rf "$HOME/.cache/go"
    if pacman -Qi go &>/dev/null && \
       [[ "$(pacman -Qi go | awk -F': ' '/Install Reason/{print $2}')" == *"dependency"* ]]; then
        sudo pacman -Rns --noconfirm go
    fi
    ok "yay built & installed"
fi

# ─────────────────────────────────────────────────────────────
step 5 9 "AUR packages"
yay -S --needed --noconfirm \
    helium-browser-bin mpv-uosc-git noctalia-greeter obsidian umbriel-git
ok "AUR packages installed"

# ─────────────────────────────────────────────────────────────
step 6 9 "Snapper tuning"
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
sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf >/dev/null << 'EOF'
[Timer]
OnCalendar=
OnCalendar=00/6:00
EOF
sudo systemctl daemon-reload
sudo systemctl restart snapper-timeline.timer
ok "timeline timer → every 6h"

# ─────────────────────────────────────────────────────────────
step 7 9 "Services"
sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2 greetd
for svc in NetworkManager bluetooth fstrim.timer udisks2 greetd; do
    ok "enabled ${D}$svc${R}"
done

# ─────────────────────────────────────────────────────────────
step 8 9 "Zsh as default shell"
if [[ ! -f /etc/zsh/zshenv ]] || ! grep -q 'ZDOTDIR' /etc/zsh/zshenv; then
    echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee -a /etc/zsh/zshenv >/dev/null
fi
chsh -s /usr/bin/zsh
ok "shell → zsh"

# ─────────────────────────────────────────────────────────────
printf "\\n${GREEN}${B}"
printf "  ╔══════════════════════════════════════════════════════════╗\\n"
printf "  ║   ✔  INSTALL COMPLETE — reboot to apply everything       ║\\n"
printf "  ╚══════════════════════════════════════════════════════════╝\\n"
printf "${R}\\n"
info "backups : ${D}$BACKUP_DIR${R}"
info "log     : ${D}$LOG_FILE${R}"
line
printf "  ${YELLOW}▸${R}  Press ${B}Enter${R} to reboot now, or ${B}Ctrl+C${R} to reboot later… "
read -r
sudo reboot
