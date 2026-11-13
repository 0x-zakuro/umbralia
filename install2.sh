#!/usr/bin/env bash
#  ██╗   ██╗███╗   ███╗██████╗ ██████╗  █████╗ ██╗     ██╗ █████╗
#  U M B R A L I A  ·  dotfiles & system installer
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL=8
CURRENT=0
START=$SECONDS
ERR_TMP="$(mktemp)"
KEEPALIVE=""
SPINNER=""
FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# ── Palette (truecolor; plain text when piped or NO_COLOR is set) ──
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  IS_TTY=1
  RST=$'\033[0m'  BOLD=$'\033[1m'
  ACCENT=$'\033[38;2;167;139;250m'
  CYAN=$'\033[38;2;125;211;252m'
  TEXT=$'\033[38;2;226;232;240m'
  MUTED=$'\033[38;2;110;118;140m'
  OK=$'\033[38;2;134;239;172m'
  WARN=$'\033[38;2;253;224;71m'
  FAIL=$'\033[38;2;248;113;113m'
  CLR=$'\r\033[2K'
else
  IS_TTY=0
  RST='' BOLD='' ACCENT='' CYAN='' TEXT='' MUTED='' OK='' WARN='' FAIL='' CLR=''
fi

# ── Lifecycle ─────────────────────────────────────────────────
cleanup() {
  [[ -n $SPINNER ]] && kill "$SPINNER" 2>/dev/null || true
  [[ -n $KEEPALIVE ]] && kill "$KEEPALIVE" 2>/dev/null || true
  [[ $IS_TTY -eq 1 ]] && printf '\033[?25h'
  rm -f "$ERR_TMP"
}
trap cleanup EXIT
trap 'printf "\n\n  %s✦ cancelled%s\n\n" "$WARN" "$RST"; exit 130' INT TERM
[[ $IS_TTY -eq 1 ]] && printf '\033[?25l'

# ── Printers ──────────────────────────────────────────────────
say()  { printf '    %s✔%s  %s\n' "$OK" "$RST" "$1"; }
note() { printf '    %s·  %s%s\n' "$MUTED" "$1" "$RST"; }
warn() { printf '    %s!%s  %s\n' "$WARN" "$RST" "$1"; }
bail() { printf '\n  %s✘ %s%s\n\n' "$FAIL" "$1" "$RST" >&2; exit 1; }

banner() {
  local -a art=(
    "██╗   ██╗███╗   ███╗██████╗ ██████╗  █████╗ ██╗     ██╗ █████╗ "
    "██║   ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║     ██║██╔══██╗"
    "██║   ██║██╔████╔██║██████╔╝██████╔╝███████║██║     ██║███████║"
    "██║   ██║██║╚██╔╝██║██╔══██╗██╔══██╗██╔══██║██║     ██║██╔══██║"
    "╚██████╔╝██║ ╚═╝ ██║██████╔╝██║  ██║██║  ██║███████╗██║██║  ██║"
    " ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝"
  )
  # lavender → sky gradient
  local -a grad=("167 139 250" "150 140 250" "130 150 250" "110 170 250" "96 190 246" "125 211 252")
  local i r g b
  printf '\n'
  for i in "${!art[@]}"; do
    if [[ $IS_TTY -eq 1 ]]; then
      read -r r g b <<<"${grad[$i]}"
      printf '   \033[38;2;%d;%d;%dm%s%s\n' "$r" "$g" "$b" "${art[$i]}" "$RST"
    else
      printf '   %s\n' "${art[$i]}"
    fi
  done
  printf '\n   %sdotfiles & system installer%s   %s·%s   %sArch · Hyprland%s\n' \
    "$TEXT" "$RST" "$MUTED" "$RST" "$MUTED" "$RST"
}

progress() {
  local w=40 filled=$(( CURRENT * 40 / TOTAL )) done_bar="" todo_bar="" i
  for ((i = 0; i < filled; i++)); do done_bar+="━"; done
  for ((i = filled; i < w; i++)); do todo_bar+="─"; done
  printf '   %s%s%s%s%s   %s%d/%d%s\n' \
    "$ACCENT" "$done_bar" "$MUTED" "$todo_bar" "$RST" "$TEXT" "$CURRENT" "$TOTAL" "$RST"
}

step() {
  CURRENT=$(( CURRENT + 1 ))
  printf '\n  %s◆%s %s%s%s\n' "$ACCENT" "$RST" "$BOLD$TEXT" "$1" "$RST"
  progress
  printf '\n'
}

# Runs a command in the foreground (so sudo can prompt if it must) while a
# print-only spinner animates. stdout is discarded; stderr is kept in a temp
# file that is shown on failure and deleted on exit.
task() {
  local label="$1"; shift
  local t0=$SECONDS rc=0 i

  if [[ $IS_TTY -eq 1 ]]; then
    (
      i=0
      while :; do
        printf '%s    %s%s%s  %s%s%s' "$CLR" "$CYAN" "${FRAMES[i]}" "$RST" "$TEXT" "$label" "$RST"
        i=$(( (i + 1) % ${#FRAMES[@]} ))
        sleep 0.08
      done
    ) &
    SPINNER=$!
  fi

  "$@" >/dev/null 2>"$ERR_TMP" || rc=$?

  if [[ -n $SPINNER ]]; then
    kill "$SPINNER" 2>/dev/null || true
    wait "$SPINNER" 2>/dev/null || true
    SPINNER=""
  fi

  if (( rc == 0 )); then
    printf '%s    %s✔%s  %s  %s%ds%s\n' "$CLR" "$OK" "$RST" "$label" "$MUTED" $(( SECONDS - t0 )) "$RST"
  else
    printf '%s    %s✘%s  %s\n' "$CLR" "$FAIL" "$RST" "$label"
    while IFS= read -r line; do
      printf '       %s%s%s\n' "$MUTED" "$line" "$RST"
    done < <(tail -n 8 "$ERR_TMP")
    bail "failed: $label"
  fi
}

# ── Preflight ─────────────────────────────────────────────────
preflight() {
  printf '\n  %s◆%s %s%sPREFLIGHT%s\n\n' "$ACCENT" "$RST" "$BOLD" "$TEXT" "$RST"
  (( EUID == 0 )) && bail "don't run as root — use your normal user"
  command -v pacman >/dev/null || bail "pacman not found — this installer is for Arch"
  curl -fsI --max-time 5 https://archlinux.org >/dev/null || bail "no internet connection"
  say "arch linux detected"
  say "network online"

  if [[ -e /var/lib/pacman/db.lck ]]; then
    if pgrep -x pacman >/dev/null || pgrep -x yay >/dev/null; then
      bail "another pacman/yay is running — close it and retry"
    fi
    warn "stale pacman lock found — removing"
    sudo rm -f /var/lib/pacman/db.lck
  fi
}

unlock_sudo() {
  note "unlocking sudo once — it stays open for the whole run"
  sudo -v
  # renew the timestamp quietly; -n means it never prompts from here
  ( while true; do sudo -n -v 2>/dev/null || true; sleep 30; done ) >/dev/null 2>&1 &
  KEEPALIVE=$!
  say "sudo unlocked"
}

# ── Helpers used by tasks ─────────────────────────────────────
refresh_fonts() { fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true; }
etc_config()    { sudo cp -r "$DOTFILES_DIR/etc/." /etc/; }
nvidia_pm() {
  echo 'ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/control}="auto"' \
    | sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null
}

build_yay() {
  local tmp
  tmp="$(mktemp -d)"
  git clone --quiet https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp" "$HOME/.cache/go"
  if pacman -Qi go >/dev/null 2>&1 &&
     [[ "$(pacman -Qi go | awk -F': ' '/Install Reason/{print $2}')" == *dependency* ]]; then
    sudo pacman -Rns --noconfirm go
  fi
}

snapper_tune() {
  local cfg
  for cfg in /etc/snapper/configs/root /etc/snapper/configs/home; do
    [[ -f "$cfg" ]] || continue
    sudo sed -i \
      -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="4"/' \
      -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="0"/' \
      -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="3"/' \
      -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
      -e 's/^TIMELINE_LIMIT_QUARTERLY=.*/TIMELINE_LIMIT_QUARTERLY="0"/' \
      -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
      "$cfg"
  done
  sudo mkdir -p /etc/systemd/system/snapper-timeline.timer.d
  sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf >/dev/null <<'EOF'
[Timer]
OnCalendar=
OnCalendar=00/6:00
EOF
  sudo systemctl daemon-reload
}

enable_services() {
  sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2 snapper-timeline.timer
  sudo systemctl enable greetd
}

zsh_default() {
  grep -q ZDOTDIR /etc/zsh/zshenv 2>/dev/null ||
    echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee -a /etc/zsh/zshenv >/dev/null
  sudo chsh -s /usr/bin/zsh "$USER"
}

# ── Steps ─────────────────────────────────────────────────────
step_dotfiles() {
  step "Dotfiles → home"
  task "copying ~/.config"     cp -r "$DOTFILES_DIR/home/kuro/.config/." "$HOME/.config/"
  task "copying ~/.local"      cp -r "$DOTFILES_DIR/home/kuro/.local/."  "$HOME/.local/"
  task "rebuilding font cache" refresh_fonts
}

step_system() {
  step "System config"
  task "merging into /etc"                   etc_config
  task "NVIDIA idle power rule (hybrid GPU)" nvidia_pm
}

step_packages() {
  step "Official packages"
  local ucode=amd-ucode
  grep -q GenuineIntel /proc/cpuinfo && ucode=intel-ucode
  local -a pkgs=(
    "$ucode" adw-gtk-theme base-devel ffmpegthumbnailer foot gthumb gvfs gvfs-mtp
    libva-mesa-driver loupe mesa mpv neovim noctalia ntfs-3g obsidian openssh starship
    thunar-archive-plugin thunar-volman tumbler udisks2 unzip vulkan-radeon xarchiver
    zed zsh zsh-autosuggestions zsh-syntax-highlighting
  )
  task "syncing & installing ${#pkgs[@]} packages" sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
}

step_yay() {
  step "AUR helper"
  if command -v yay >/dev/null; then
    note "yay already installed"
  else
    sudo -v   # re-arm the timestamp right before makepkg needs it
    task "building yay" build_yay
    hash -r   # forget cached PATH lookups so the new binary is seen
    command -v yay >/dev/null || bail "yay built but not on PATH — check 'pacman -Ql yay'"
  fi
}

step_aur() {
  step "AUR packages"
  hash -r
  local -a aur=(
    deckcraft-bin flow-browser-bin gridcraft-bin localsend-bin mpv-uosc-git
    noctalia-greeter qt6ct-kde rayburst-bin umbriel-git wordcraft-bin
  )
  sudo -v
  task "installing ${#aur[@]} AUR packages" yay -S --needed --noconfirm "${aur[@]}"
}

step_snapper() {
  step "Snapper tuning"
  task "timeline limits + 6-hourly timer" snapper_tune
}

step_services() {
  step "Services"
  task "enabling services" enable_services
}

step_shell() {
  step "Shell"
  task "zsh as default shell" zsh_default
}

# ── Finish ────────────────────────────────────────────────────
finish() {
  local mins=$(( (SECONDS - START) / 60 )) secs=$(( (SECONDS - START) % 60 ))
  printf '\n  %s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n' "$ACCENT" "$RST"
  printf '  %s✦ all set%s   %sfinished in %dm %02ds%s\n\n' "$OK$BOLD" "$RST" "$MUTED" "$mins" "$secs" "$RST"
  local s
  for (( s = 10; s > 0; s-- )); do
    printf '%s  %srebooting in%s %s%2ds%s   %s· ctrl+c to cancel%s' \
      "$CLR" "$MUTED" "$RST" "$ACCENT$BOLD" "$s" "$RST" "$MUTED" "$RST"
    sleep 1
  done
  printf '\n\n  %s↻ rebooting…%s\n\n' "$ACCENT" "$RST"
  sudo reboot
}

# ── Main ──────────────────────────────────────────────────────
main() {
  banner
  preflight
  unlock_sudo
  step_dotfiles
  step_system
  step_packages
  step_yay
  step_aur
  step_snapper
  step_services
  step_shell
  finish
}

main "$@"
