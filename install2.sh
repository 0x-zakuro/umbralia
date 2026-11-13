#!/usr/bin/env bash
#  U M B R A L I A  ·  dotfiles & system installer
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOTAL=8
CURRENT=0
START=$SECONDS
ERR_TMP="$(mktemp)"
KEEPALIVE=""
SPINNER=""

# ── Palette: sampled from the sunset (plum night, lavender, orchid, coral, gold, cream)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  IS_TTY=1
  RST=$'\033[0m'
  BOLD=$'\033[1m'
  C_PLUM=$'\033[38;2;78;62;122m'
  C_MAUVE=$'\033[38;2;128;118;168m'
  C_LAV=$'\033[38;2;167;139;250m'
  C_PINK=$'\033[38;2;244;127;176m'
  C_CORAL=$'\033[38;2;255;122;107m'
  C_GOLD=$'\033[38;2;255;196;107m'
  C_CREAM=$'\033[38;2;255;243;230m'
  CLR=$'\r\033[2K'
  # comet trail for the spinner: head is cream, tail fades into plum
  TRAIL=("$C_CREAM" "$C_GOLD" "$C_CORAL" "$C_PINK" "$C_PINK" "$C_LAV" "$C_LAV"
         "$C_MAUVE" "$C_MAUVE" "$C_PLUM" "$C_PLUM" "$C_PLUM")
else
  IS_TTY=0
  RST='' BOLD='' C_PLUM='' C_MAUVE='' C_LAV='' C_PINK='' C_CORAL='' C_GOLD='' C_CREAM='' CLR=''
  TRAIL=('' '' '' '' '' '' '' '' '' '' '' '')
fi

# ── Lifecycle ─────────────────────────────────────────────────
cleanup() {
  [[ -n $SPINNER ]] && kill "$SPINNER" 2>/dev/null || true
  [[ -n $KEEPALIVE ]] && kill "$KEEPALIVE" 2>/dev/null || true
  (( IS_TTY )) && printf '\033[?25h'
  rm -f "$ERR_TMP"
}
trap cleanup EXIT
trap 'printf "\n\n  %s✦ cancelled%s\n\n" "$C_CORAL" "$RST"; exit 130' INT TERM
(( IS_TTY )) && printf '\033[?25l'

# ── Color helpers ─────────────────────────────────────────────
# sky T (0-100): lavender -> orchid -> gold, prints an escape code
sky() {
  (( IS_TTY )) || return 0
  local t=$1 a b s
  if (( t < 50 )); then
    a=(167 139 250); b=(244 127 176); s=$(( t * 2 ))
  else
    a=(244 127 176); b=(255 196 107); s=$(( (t - 50) * 2 ))
  fi
  printf '\033[38;2;%d;%d;%dm' \
    $(( a[0] + (b[0] - a[0]) * s / 100 )) \
    $(( a[1] + (b[1] - a[1]) * s / 100 )) \
    $(( a[2] + (b[2] - a[2]) * s / 100 ))
}

# rule: a full-width gradient divider
rule() {
  local i bar=""
  for (( i = 0; i < 56; i++ )); do bar+="$(sky $(( i * 100 / 56 )))━"; done
  printf '%s%s' "$bar" "$RST"
}

# ── Printers ──────────────────────────────────────────────────
say()  { printf '    %s✔%s  %s\n' "$C_PINK" "$RST" "$1"; }
note() { printf '    %s·%s  %s%s\n' "$C_MAUVE" "$RST" "$C_MAUVE" "$1$RST"; }
warn() { printf '    %s!%s  %s\n' "$C_GOLD" "$RST" "$1"; }
bail() { printf '\n  %s✘ %s%s\n\n' "$C_CORAL" "$1" "$RST" >&2; exit 1; }

banner() {
  local -a art=(
    "██╗   ██╗███╗   ███╗██████╗ ██████╗  █████╗ ██╗     ██╗ █████╗ "
    "██║   ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║     ██║██╔══██╗"
    "██║   ██║██╔████╔██║██████╔╝██████╔╝███████║██║     ██║███████║"
    "██║   ██║██║╚██╔╝██║██╔══██╗██╔══██╗██╔══██║██║     ██║██╔══██║"
    "╚██████╔╝██║ ╚═╝ ██║██████╔╝██║  ██║██║  ██║███████╗██║██║  ██║"
    " ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝"
  )
  local i
  printf '\n'
  for i in "${!art[@]}"; do
    # top line is gold, bottom is lavender
    printf '   %s%s%s\n' "$(sky $(( 100 - i * 20 )))" "${art[$i]}" "$RST"
  done
  printf '\n   %s%s%s\n' "$(rule)" "" ""
  # typewriter tagline
  local tag="dotfiles & system installer  ·  Arch · Hyprland"
  printf '   '
  local j
  for (( j = 0; j < ${#tag}; j++ )); do
    printf '%s%s' "$C_CREAM" "${tag:j:1}"
    (( IS_TTY )) && sleep 0.012
  done
  printf '%s\n' "$RST"
}

progress() {
  local w=44 filled=$(( CURRENT * 44 / TOTAL )) i bar=""
  for (( i = 0; i < w; i++ )); do
    if (( i < filled )); then
      bar+="$(sky $(( i * 100 / w )))━"
    else
      bar+="${C_PLUM}─"
    fi
  done
  printf '    %s%s  %s%d%s/%d%s\n' "$bar" "$RST" "$C_CREAM" "$CURRENT" "$C_MAUVE" "$TOTAL" "$RST"
}

step() {
  CURRENT=$(( CURRENT + 1 ))
  sudo -v   # prompts only if the password expired, and always before any spinner starts
  printf '\n  %s◆ %s%s%s%s\n' "$C_GOLD" "$BOLD$C_CREAM" "$1" "$RST" ""
  progress
  printf '\n'
}

# ── Spinner: a comet that sweeps across 12 cells ──────────────
spin() {
  local label=$1 f=0 k d line
  while :; do
    line=""
    for (( k = 0; k < 12; k++ )); do
      d=$(( (f - k + 12) % 12 ))
      line+="${TRAIL[d]}●"
    done
    printf '%s    %s%s  %s%s%s' "$CLR" "$line" "$RST" "$C_CREAM" "$label" "$RST"
    f=$(( (f + 1) % 12 ))
    sleep 0.07
  done
}

# task LABEL CMD... — runs CMD in the foreground (so sudo can prompt if it must)
# while the comet animates. stdout is discarded; stderr goes to a temp file
# that is shown on failure and deleted on exit.
task() {
  local label=$1; shift
  local t0=$SECONDS rc=0 line

  if (( IS_TTY )); then
    spin "$label" &
    SPINNER=$!
  fi

  "$@" >/dev/null 2>"$ERR_TMP" || rc=$?

  if [[ -n $SPINNER ]]; then
    kill "$SPINNER" 2>/dev/null || true
    wait "$SPINNER" 2>/dev/null || true
    SPINNER=""
  fi

  if (( rc == 0 )); then
    printf '%s    %s✔%s  %s%s  %s%ds%s\n' "$CLR" "$C_PINK" "$RST" "$C_CREAM" "$label" "$C_MAUVE" $(( SECONDS - t0 )) "$RST"
  else
    printf '%s    %s✘%s  %s%s\n' "$CLR" "$C_CORAL" "$RST" "$C_CREAM" "$label"
    while IFS= read -r line; do
      printf '       %s%s%s\n' "$C_MAUVE" "$line" "$RST"
    done < <(tail -n 8 "$ERR_TMP")
    bail "failed: $label"
  fi
}

# ── Preflight ─────────────────────────────────────────────────
preflight() {
  printf '\n  %s◆ %s%sPREFLIGHT%s\n\n' "$C_GOLD" "$BOLD" "$C_CREAM" "$RST"
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

# ── Task bodies ───────────────────────────────────────────────
# Each multi-step body uses explicit "|| return 1" because set -e is
# ignored inside functions run from a || context, which task() does.
refresh_fonts() { fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true; }

etc_config() { sudo cp -r "$DOTFILES_DIR/etc/." /etc/; }

nvidia_pm() {
  echo 'ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/control}="auto"' \
    | sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null
}

build_yay() {
  local tmp
  tmp="$(mktemp -d)" || return 1
  git clone --quiet https://aur.archlinux.org/yay.git "$tmp/yay" || return 1
  (cd "$tmp/yay" && makepkg -si --noconfirm) || return 1
  rm -rf "$tmp" "$HOME/.cache/go"
  if pacman -Qi go >/dev/null 2>&1 &&
     [[ "$(pacman -Qi go | awk -F': ' '/Install Reason/{print $2}')" == *dependency* ]]; then
    sudo pacman -Rns --noconfirm go || return 1
  fi
  command -v yay >/dev/null
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
      "$cfg" || return 1
  done
  sudo mkdir -p /etc/systemd/system/snapper-timeline.timer.d || return 1
  sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf >/dev/null <<'EOF' || return 1
[Timer]
OnCalendar=
OnCalendar=00/6:00
EOF
  sudo systemctl daemon-reload
}

enable_services() {
  sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2 snapper-timeline.timer || return 1
  sudo systemctl enable greetd
}

zsh_default() {
  if ! grep -q ZDOTDIR /etc/zsh/zshenv 2>/dev/null; then
    echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee -a /etc/zsh/zshenv >/dev/null || return 1
  fi
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
    return
  fi
  task "building yay  (this one is slow)" build_yay
  hash -r
  command -v yay >/dev/null || bail "yay built but not on PATH — check: pacman -Ql yay | grep bin"
}

step_aur() {
  step "AUR packages"
  local -a aur=(
    deckcraft-bin flow-browser-bin gridcraft-bin localsend-bin mpv-uosc-git
    noctalia-greeter qt6ct-kde rayburst-bin umbriel-git wordcraft-bin
  )
  hash -r
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
  local elapsed=$(( SECONDS - START )) s i w=30 filled bar
  printf '\n  %s\n' "$(rule)"
  printf '  %s✦ all set%s   %sin %dm %02ds%s\n\n' "$C_PINK$BOLD" "$RST" "$C_MAUVE" \
    $(( elapsed / 60 )) $(( elapsed % 60 )) "$RST"
  for (( s = 10; s > 0; s-- )); do
    filled=$(( s * w / 10 )); bar=""
    for (( i = 0; i < w; i++ )); do
      if (( i < filled )); then bar+="$(sky $(( i * 100 / w )))━"; else bar+="${C_PLUM}─"; fi
    done
    printf '%s  %s%s  %srebooting in%s %s%2ds%s  %s· ctrl+c to cancel%s' \
      "$CLR" "$bar" "$RST" "$C_MAUVE" "$RST" "$C_GOLD$BOLD" "$s" "$RST" "$C_MAUVE" "$RST"
    sleep 1
  done
  printf '\n\n  %s↻ rebooting…%s\n\n' "$C_LAV" "$RST"
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
