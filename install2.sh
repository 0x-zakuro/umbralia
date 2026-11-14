#!/usr/bin/env bash
#  U M B R A L I A  ·  dotfiles & system installer
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$HOME/umbralia-debug.log"   # TEMP-DEBUG: remove when finished
: >"$LOG"                        # TEMP-DEBUG
TOTAL=8
CURRENT=0
START=$SECONDS
LABEL=""
KEEPALIVE=""
CANCELLED=0
BAILED=0

# ── Terminal capability ───────────────────────────────────────
if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  IS_TTY=1
  case "${COLORTERM:-}" in
    truecolor|24bit) MODE=truecolor ;;
    *)
      case "${TERM:-}" in
        *foot*|*kitty*|*alacritty*|*wezterm*) MODE=truecolor ;;
        *256color*) MODE=256 ;;
        *) MODE=16 ;;
      esac ;;
  esac
  RST=$'\033[0m'
  BOLD=$'\033[1m'
else
  IS_TTY=0
  MODE=none
  RST=''
  BOLD=''
fi

# ── Palette, sampled from the sunset ──────────────────────────
declare -A RGB=(
  [plum]="78 62 122"    [mauve]="128 118 168" [lav]="167 139 250"
  [orchid]="214 130 200" [pink]="244 127 176" [coral]="255 122 107"
  [gold]="255 196 107"  [cream]="255 243 230"
)
declare -A X256=(
  [plum]=60 [mauve]=103 [lav]=147 [orchid]=176
  [pink]=211 [coral]=209 [gold]=215 [cream]=230
)
declare -A X16=(
  [plum]=34 [mauve]=90 [lav]=35 [orchid]=95
  [pink]=95 [coral]=91 [gold]=93 [cream]=97
)
STOPS=(lav orchid pink coral gold)

fg() {
  local r g b
  case $MODE in
    truecolor) read -r r g b <<<"${RGB[$1]}"; printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b" ;;
    256)       printf '\033[38;5;%dm' "${X256[$1]}" ;;
    16)        printf '\033[%dm' "${X16[$1]}" ;;
    none)      ;;
  esac
}

# grad_at <0-100>: a color along the sunset gradient
grad_at() {
  local t=$1 n=$(( ${#STOPS[@]} - 1 )) seg f a b r1 g1 b1 r2 g2 b2
  seg=$(( t * n / 100 )); (( seg >= n )) && seg=$(( n - 1 ))
  f=$(( t * n - seg * 100 ))
  a=${STOPS[seg]}; b=${STOPS[seg+1]}
  if [[ $MODE == truecolor ]]; then
    read -r r1 g1 b1 <<<"${RGB[$a]}"
    read -r r2 g2 b2 <<<"${RGB[$b]}"
    printf '\033[38;2;%d;%d;%dm' \
      $(( r1 + (r2 - r1) * f / 100 )) \
      $(( g1 + (g2 - g1) * f / 100 )) \
      $(( b1 + (b2 - b1) * f / 100 ))
  else
    if (( f < 50 )); then fg "$a"; else fg "$b"; fi
  fi
}

# gtext "text": the text, colored along the gradient
gtext() {
  local s=$1 i n=${#1}
  for (( i = 0; i < n; i++ )); do
    grad_at $(( n > 1 ? i * 100 / (n - 1) : 0 ))
    printf '%s' "${s:i:1}"
  done
  printf '%s' "$RST"
}

rule() {
  local i
  for (( i = 0; i < 60; i++ )); do
    grad_at $(( i * 100 / 59 ))
    printf '━'
  done
  printf '%s' "$RST"
}

progress_bar() {
  local w=40 filled=$(( CURRENT * 40 / TOTAL )) i
  for (( i = 0; i < w; i++ )); do
    if (( i < filled )); then
      grad_at $(( i * 100 / (w - 1) )); printf '━'
    else
      fg plum; printf '─'
    fi
  done
  printf '%s' "$RST"
}

# ── Printers ──────────────────────────────────────────────────
log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >>"$LOG"; }   # TEMP-DEBUG
ok()   { printf '    %s✔%s  %s%s%s\n' "$(fg pink)" "$RST" "$(fg cream)" "$1" "$RST"; log "OK: $1"; }
note() { printf '    %s·%s  %s%s%s\n' "$(fg mauve)" "$RST" "$(fg mauve)" "$1" "$RST"; log "NOTE: $1"; }
warn() { printf '    %s!%s  %s%s%s\n' "$(fg gold)" "$RST" "$(fg cream)" "$1" "$RST"; log "WARN: $1"; }
bail() {
  BAILED=1
  printf '\n  %s✘ %s%s\n  %slog: %s%s\n\n' "$(fg coral)" "$1" "$RST" "$(fg mauve)" "$LOG" "$RST" >&2
  log "BAIL: $1"
  exit 1
}

banner() {
  local -a art=(
    "██╗   ██╗███╗   ███╗██████╗ ██████╗  █████╗ ██╗     ██╗ █████╗ "
    "██║   ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║     ██║██╔══██╗"
    "██║   ██║██╔████╔██║██████╔╝██████╔╝███████║██║     ██║███████║"
    "██║   ██║██║╚██╔╝██║██╔══██╗██╔══██╗██╔══██║██║     ██║██╔══██║"
    "╚██████╔╝██║ ╚═╝ ██║██████╔╝██║  ██║██║  ██║███████╗██║██║  ██║"
    " ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝"
  )
  local i j tag="dotfiles & system installer  ·  Arch · Hyprland"
  printf '\n'
  for i in "${!art[@]}"; do
    printf '   '
    grad_at $(( 100 - i * 18 ))
    printf '%s%s\n' "${art[$i]}" "$RST"
  done
  printf '\n   %s\n\n   ' "$(rule)"
  for (( j = 0; j < ${#tag}; j++ )); do
    printf '%s%s' "$(fg cream)" "${tag:j:1}"
    if (( IS_TTY )); then sleep 0.01; fi
  done
  printf '%s\n' "$RST"
}

ui_step() {
  CURRENT=$(( CURRENT + 1 ))
  log "=== STEP $CURRENT/$TOTAL: $1"                       # TEMP-DEBUG
  sudo -v                                                   # prompts here, on a clean line
  printf '\n  %s%02d%s  %s%s%s%s\n' "$(fg gold)" "$CURRENT" "$RST" "$BOLD" "$(fg cream)" "$1" "$RST"
  printf '      %s  %s%d%s/%d%s\n\n' "$(progress_bar)" "$(fg cream)" "$CURRENT" "$(fg mauve)" "$TOTAL" "$RST"
}

# run LABEL CMD... — output goes to the log; prompts still show on screen.
# set -e stops the script on failure, and cleanup() reports it.
run() {
  local label=$1; shift
  local t0=$SECONDS
  LABEL=$label
  log "--- TASK: $label"                                     # TEMP-DEBUG
  log "    cmd: $*"                                          # TEMP-DEBUG
  printf '    %s◌%s  %s%s' "$(fg lav)" "$RST" "$(fg cream)" "$label"
  "$@" >>"$LOG" 2>&1
  local dt=$(( SECONDS - t0 ))
  log "    done in ${dt}s"                                   # TEMP-DEBUG
  printf '\r\033[2K    %s✔%s  %s%s  %s%ds%s\n' "$(fg pink)" "$RST" "$(fg cream)" "$label" "$(fg mauve)" "$dt" "$RST"
  LABEL=""
}

# ── Lifecycle ─────────────────────────────────────────────────
cleanup() {
  local rc=$?
  [[ -n $KEEPALIVE ]] && kill "$KEEPALIVE" 2>/dev/null || true
  if (( IS_TTY )); then printf '\033[?25h'; fi
  if (( rc != 0 && CANCELLED == 0 && BAILED == 0 )); then
    printf '\r\033[2K    %s✘%s  %s%s\n' "$(fg coral)" "$RST" "$(fg cream)" "${LABEL:-unexpected error}"
    printf '\n  %slast lines of the log:%s\n' "$(fg mauve)" "$RST"
    tail -n 25 "$LOG" | sed 's/^/      /'
    printf '\n  %sfull log: %s%s\n\n' "$(fg mauve)" "$LOG" "$RST"
  fi
  log "EXIT rc=$rc"                                          # TEMP-DEBUG
}
trap cleanup EXIT
trap 'CANCELLED=1; printf "\n\n  %s✦ cancelled%s\n\n" "$(fg coral)" "$RST"; exit 130' INT TERM
if (( IS_TTY )); then printf '\033[?25l'; fi

# ── Preflight ─────────────────────────────────────────────────
preflight() {
  printf '\n  %s◆ PREFLIGHT%s\n\n' "$(fg gold)" "$RST"
  log "=== ENVIRONMENT"                                       # TEMP-DEBUG
  log "user=$USER home=$HOME bash=$BASH_VERSION term=${TERM:-} colorterm=${COLORTERM:-} mode=$MODE"  # TEMP-DEBUG
  log "PATH=$PATH"                                           # TEMP-DEBUG

  (( EUID == 0 )) && bail "don't run as root, use your normal user"
  command -v pacman >/dev/null || bail "pacman not found, this installer is for Arch"
  curl -fsI --max-time 5 https://archlinux.org >/dev/null || bail "no internet connection"
  ok "arch linux detected"
  ok "network online"

  if [[ -e /var/lib/pacman/db.lck ]]; then
    if pgrep -x pacman >/dev/null || pgrep -x yay >/dev/null; then
      bail "another pacman/yay is running, close it and retry"
    fi
    warn "stale pacman lock found, removing"
    sudo rm -f /var/lib/pacman/db.lck
  fi
}

unlock_sudo() {
  note "unlocking sudo once, it stays open for the whole run"
  sudo -v
  ( while true; do sudo -n -v 2>/dev/null || true; sleep 30; done ) >/dev/null 2>&1 &
  KEEPALIVE=$!
  ok "sudo unlocked"
}

# ── Task bodies ───────────────────────────────────────────────
refresh_fonts() { fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true; }

etc_config() { sudo cp -r "$DOTFILES_DIR/etc/." /etc/; }

nvidia_pm() {
  echo 'ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/control}="auto"' \
    | sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null
}

build_yay() {
  local tmp
  tmp="$(mktemp -d)"
  log "build_yay: tmp=$tmp"                                  # TEMP-DEBUG
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp" "$HOME/.cache/go"
  if pacman -Qi go >/dev/null 2>&1 &&
     [[ "$(pacman -Qi go | awk -F': ' '/Install Reason/{print $2}')" == *dependency* ]]; then
    sudo pacman -Rns --noconfirm go
  fi
  log "build_yay: yay now at $(command -v yay || echo none)" # TEMP-DEBUG
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
  if ! grep -q ZDOTDIR /etc/zsh/zshenv 2>/dev/null; then
    echo 'export ZDOTDIR=$HOME/.config/zsh' | sudo tee -a /etc/zsh/zshenv >/dev/null
  fi
  sudo chsh -s /usr/bin/zsh "$USER"
}

# ── Steps ─────────────────────────────────────────────────────
step_dotfiles() {
  ui_step "Dotfiles → home"
  run "copying ~/.config"     cp -r "$DOTFILES_DIR/home/kuro/.config/." "$HOME/.config/"
  run "copying ~/.local"      cp -r "$DOTFILES_DIR/home/kuro/.local/."  "$HOME/.local/"
  run "rebuilding font cache" refresh_fonts
}

step_system() {
  ui_step "System config"
  run "merging into /etc"                    etc_config
  run "NVIDIA idle power rule (hybrid GPU)"  nvidia_pm
}

step_packages() {
  ui_step "Official packages"
  local ucode=amd-ucode
  if grep -q GenuineIntel /proc/cpuinfo; then ucode=intel-ucode; fi
  local -a pkgs=(
    "$ucode" adw-gtk-theme base-devel ffmpegthumbnailer foot gthumb gvfs gvfs-mtp
    libva-mesa-driver loupe mesa mpv neovim noctalia ntfs-3g obsidian openssh starship
    thunar-archive-plugin thunar-volman tumbler udisks2 unzip vulkan-radeon xarchiver
    zed zsh zsh-autosuggestions zsh-syntax-highlighting
  )
  run "syncing & installing ${#pkgs[@]} packages" sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
}

step_yay() {
  ui_step "AUR helper"
  if command -v yay >/dev/null; then
    ok "yay already installed"
    return
  fi
  run "building yay (compiles from source, a few minutes)" build_yay
  hash -r
  command -v yay >/dev/null || bail "yay built but not on PATH, see $LOG"
}

step_aur() {
  ui_step "AUR packages"
  local -a aur=(
    deckcraft-bin flow-browser-bin gridcraft-bin localsend-bin mpv-uosc-git
    noctalia-greeter qt6ct-kde rayburst-bin umbriel-git wordcraft-bin
  )
  hash -r
  run "installing ${#aur[@]} AUR packages" yay -S --needed --noconfirm "${aur[@]}"
}

step_snapper() {
  ui_step "Snapper tuning"
  run "timeline limits + 6-hourly timer" snapper_tune
}

step_services() {
  ui_step "Services"
  run "enabling services" enable_services
}

step_shell() {
  ui_step "Shell"
  run "zsh as default shell" zsh_default
}

# ── Finish ────────────────────────────────────────────────────
finish() {
  local elapsed=$(( SECONDS - START )) s i w=40 filled
  log "FINISHED in ${elapsed}s"                              # TEMP-DEBUG
  printf '\n  %s\n' "$(rule)"
  printf '\n  %s✦ all set%s   %sin %dm %02ds%s\n\n' \
    "$(fg pink)$BOLD" "$RST" "$(fg mauve)" $(( elapsed / 60 )) $(( elapsed % 60 )) "$RST"
  for (( s = 10; s > 0; s-- )); do
    filled=$(( s * w / 10 ))
    printf '\r  '
    for (( i = 0; i < w; i++ )); do
      if (( i < filled )); then
        grad_at $(( i * 100 / (w - 1) )); printf '━'
      else
        fg plum; printf '─'
      fi
    done
    printf '%s   %srebooting in %s%2ds%s   %sctrl+c to cancel%s' \
      "$RST" "$(fg mauve)" "$(fg gold)$BOLD" "$s" "$RST" "$(fg mauve)" "$RST"
    sleep 1
  done
  printf '\n\n  %s↻ rebooting…%s\n\n' "$(fg lav)" "$RST"
  sudo reboot
}

# ── Main ──────────────────────────────────────────────────────
main() {
  banner
  log "=== UMBRALIA run started $(date)"                    # TEMP-DEBUG
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
