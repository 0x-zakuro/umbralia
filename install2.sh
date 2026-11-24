#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────
#  Umbralia — dotfiles & system installer for Arch Linux
# ──────────────────────────────────────────────────────────────────────────
set -Eeuo pipefail

readonly VERSION="1.0.0"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR
readonly LOG_FILE="$HOME/umbralia-install.log"
readonly TOTAL_STEPS=8

# ── Command line ─────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Umbralia $VERSION - dotfiles & system installer for Arch Linux

Usage: ${0##*/} [options]

Options:
  --no-color     Disable colored output (NO_COLOR is also respected)
  -V, --version  Show the version and exit
  -h, --help     Show this help and exit

If the install fails or is interrupted, a log is saved to ~/umbralia-install.log.
EOF
}

for arg in "$@"; do
  case $arg in
    -h | --help) usage; exit 0 ;;
    -V | --version) printf 'umbralia %s\n' "$VERSION"; exit 0 ;;
    --no-color) export NO_COLOR=1 ;;
    *) printf 'Unknown option: %s\n\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

# ── Package lists ────────────────────────────────────────────────────────
readonly PACMAN_PKGS=(
  adw-gtk-theme base-devel ffmpegthumbnailer foot gthumb gvfs gvfs-mtp
  libva-mesa-driver loupe mesa mpv neovim noctalia ntfs-3g obsidian openssh
  starship thunar-archive-plugin thunar-volman tumbler udisks2 unzip
  vulkan-radeon xarchiver zed zsh zsh-autosuggestions zsh-syntax-highlighting
)

readonly AUR_PKGS=(
  deckcraft-bin flow-browser-bin gridcraft-bin localsend-bin mpv-uosc
  noctalia-greeter qt6ct-kde rayburst-bin umbriel-git wordcraft-bin
)

readonly SNAPPER_LIMITS=(
  TIMELINE_LIMIT_HOURLY=4
  TIMELINE_LIMIT_DAILY=0
  TIMELINE_LIMIT_WEEKLY=3
  TIMELINE_LIMIT_MONTHLY=3
  TIMELINE_LIMIT_QUARTERLY=0
  TIMELINE_LIMIT_YEARLY=0
)

# ── Terminal capabilities (decided before output is redirected) ──────────
UI_TTY=0
if [[ -t 1 && ${TERM:-dumb} != dumb ]]; then UI_TTY=1; fi

COLOR=0
if (( UI_TTY )) && [[ -z ${NO_COLOR:-} ]]; then COLOR=1; fi

UNICODE=0
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *[Uu][Tt][Ff]-8* | *[Uu][Tt][Ff]8*) UNICODE=1 ;;
esac

if (( COLOR )); then
  B=$'\033[1m' DIM=$'\033[2m' R=$'\033[0m'
  ACCENT=$'\033[38;5;141m' GREEN=$'\033[38;5;114m' YELLOW=$'\033[38;5;179m'
  RED=$'\033[38;5;203m' BLUE=$'\033[38;5;110m' GRAY=$'\033[38;5;244m'
else
  B='' DIM='' R='' ACCENT='' GREEN='' YELLOW='' RED='' BLUE='' GRAY=''
fi

if (( UNICODE )); then
  S_OK='✓' S_FAIL='✗' S_WARN='!' S_INFO='•' S_ARROW='→' S_ELLIPSIS='…' S_DOT='·'
  SPIN_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  BAR_ON='█' BAR_OFF='░'
  HL='─' VL='│' TL='╭' TR='╮' BL='╰' BR='╯' ML='├' MR='┤'
else
  S_OK='+' S_FAIL='x' S_WARN='!' S_INFO='-' S_ARROW='->' S_ELLIPSIS='~' S_DOT='-'
  SPIN_FRAMES=('|' '/' '-' '\')
  BAR_ON='#' BAR_OFF='-'
  HL='-' VL='|' TL='+' TR='+' BL='+' BR='+' ML='+' MR='+'
fi

term_cols() {
  local c=""
  if (( UI_TTY )); then
    c="$(stty size <&3 2>/dev/null | cut -d' ' -f2 || true)"
  fi
  [[ $c =~ ^[0-9]+$ ]] || c=${COLUMNS:-80}
  [[ $c =~ ^[0-9]+$ ]] || c=80
  printf '%d' "$c"
}

# ── State ────────────────────────────────────────────────────────────────
TMP_DIR="$(mktemp -d)"
readonly TMP_DIR
readonly TMP_LOG="$TMP_DIR/install.log"
STEP=0
STEP_TITLE=""
STEP_T0=0
STEP_NAMES=()
STEP_TIMES=()
FINISHED=0
REPORTED=0
ERR_LINE=""
CHILD_PID=""
SPIN_PID=""
SUDO_PID=""
UCODE=""
SCRIPT_T0=0

# fd 3 / fd 4 are the real terminal; stdout and stderr become the log file
exec 3>&1 4>&2
exec >>"$TMP_LOG" 2>&1

COLS="$(term_cols)"
W=$(( COLS - 4 ))
if (( W > 68 )); then W=68; fi
if (( W < 44 )); then W=44; fi
printf -v RULE '%*s' "$W" ''
RULE=${RULE// /$HL}

# ── Time and text helpers ────────────────────────────────────────────────
now_ms() {
  local t=${EPOCHREALTIME/[.,]/}
  printf '%d' $(( t / 1000 ))
}

fmt_ms() {
  local ms=$1
  if (( ms < 10000 )); then
    printf '%d.%ds' $(( ms / 1000 )) $(( ms % 1000 / 100 ))
  elif (( ms < 60000 )); then
    printf '%ds' $(( ms / 1000 ))
  else
    printf '%dm%02ds' $(( ms / 60000 )) $(( ms % 60000 / 1000 ))
  fi
}

trunc() {
  local s=$1 n=$2
  if (( n < 2 )); then return 0; fi
  if (( ${#s} > n )); then
    printf '%s%s' "${s:0:n-1}" "$S_ELLIPSIS"
  else
    printf '%s' "$s"
  fi
}

# Print to the terminal and to the log
emit() { local s; printf -v s "$@"; printf '%s\n' "$s" >&3; printf '%s\n' "$s"; }
emit_err() { local s; printf -v s "$@"; printf '%s\n' "$s" >&4; printf '%s\n' "$s"; }

# Last non-empty line of recent output, stripped of control codes
last_line() {
  tail -c 400 "$TMP_LOG" 2>/dev/null | tr '\r' '\n' \
    | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/[^[:print:]]//g' -e 's/^[[:space:]]*//' \
    | grep -v '^$' | tail -n 1 || true
}

# Last N lines of the log from byte offset $2 onward, stripped of control codes
tail_since() {
  tail -c "+$(( $2 + 1 ))" "$TMP_LOG" | tr '\r' '\n' \
    | sed -e 's/\x1b\[[0-9;?]*[A-Za-z]//g' -e 's/[[:space:]]*$//' \
    | grep -v '^$' | tail -n "$1" || true
}

# ── UI components ────────────────────────────────────────────────────────
info() { emit '  %s%s%s  %s' "$BLUE" "$S_INFO" "$R" "$*"; }
pass() { emit '  %s%s%s  %s' "$GREEN" "$S_OK" "$R" "$*"; }
warn() { emit '  %s%s%s  %s' "$YELLOW" "$S_WARN" "$R" "$*"; }
die() {
  REPORTED=1
  emit_err '  %s%s%s  %s' "$RED" "$S_FAIL" "$R" "$*"
  exit 1
}

section() {
  emit ''
  emit '  %s%s%s' "$B" "$1" "$R"
  emit '  %s%s%s' "$GRAY" "$RULE" "$R"
}

progress_bar() { # done total width
  local done_n=$1 total=$2 width=$3 filled i
  filled=$(( done_n * width / total ))
  printf '%s' "$ACCENT"
  for (( i = 0; i < filled; i++ )); do printf '%s' "$BAR_ON"; done
  printf '%s%s' "$R" "$GRAY"
  for (( i = filled; i < width; i++ )); do printf '%s' "$BAR_OFF"; done
  printf '%s' "$R"
}

finish_step() {
  if (( STEP > 0 )); then
    STEP_NAMES+=("$STEP_TITLE")
    STEP_TIMES+=($(( $(now_ms) - STEP_T0 )))
  fi
}

step() {
  finish_step
  STEP=$(( STEP + 1 ))
  STEP_TITLE=$1
  STEP_T0="$(now_ms)"
  emit ''
  emit '  %s%s%d/%d%s  %s%s%s' "$ACCENT" "$B" "$STEP" "$TOTAL_STEPS" "$R" "$B" "$1" "$R"
  emit '  %s  %s%3d%%%s' "$(progress_bar $(( STEP - 1 )) "$TOTAL_STEPS" $(( W - 8 )))" \
    "$GRAY" $(( (STEP - 1) * 100 / TOTAL_STEPS )) "$R"
}

banner() {
  local -a art=(
    '██╗   ██╗███╗   ███╗██████╗ ██████╗  █████╗ ██╗     ██╗ █████╗ '
    '██║   ██║████╗ ████║██╔══██╗██╔══██╗██╔══██╗██║     ██║██╔══██╗'
    '██║   ██║██╔████╔██║██████╔╝██████╔╝███████║██║     ██║███████║'
    '██║   ██║██║╚██╔╝██║██╔══██╗██╔══██╗██╔══██║██║     ██║██╔══██║'
    '╚██████╔╝██║ ╚═╝ ██║██████╔╝██║  ██║██║  ██║███████╗██║██║  ██║'
    ' ╚═════╝ ╚═╝     ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═╝'
  )
  local -a grad=(93 99 105 141 177 213)
  local i c
  emit ''
  if (( UNICODE && COLS >= 70 )); then
    for i in "${!art[@]}"; do
      c=''
      if (( COLOR )); then printf -v c '\033[38;5;%dm' "${grad[i]}"; fi
      emit '  %s%s%s' "$c" "${art[i]}" "$R"
    done
    emit ''
    emit '  %sdotfiles & system installer  %s  v%s%s' "$GRAY" "$S_DOT" "$VERSION" "$R"
  else
    emit '  %s%sUMBRALIA%s  %sdotfiles & system installer  %s  v%s%s' \
      "$ACCENT" "$B" "$R" "$GRAY" "$S_DOT" "$VERSION" "$R"
  fi
}

sysinfo() {
  local os cpu mem src
  os="$(grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || true)"
  cpu="$(awk -F': ' '/^model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null | tr -s ' ' || true)"
  mem="$(awk '/^MemTotal/{printf "%.0f GiB", $2/1048576}' /proc/meminfo 2>/dev/null || true)"
  src="${DOTFILES_DIR/#"$HOME"/\~}"
  emit ''
  local k v
  while IFS='|' read -r k v; do
    [[ -n $v ]] || continue
    emit '  %s%-8s%s %s' "$GRAY" "$k" "$R" "$(trunc "$v" $(( W - 11 )))"
  done <<EOF
system|${os:-Linux}
kernel|$(uname -r)
cpu|$cpu
memory|$mem
user|$(id -un)@$(uname -n)
source|$src
EOF
}

# Box drawing (rows take a plain string for width and a colored one for display)
box_edge() { # left right
  local s
  printf -v s '%*s' $(( W - 2 )) ''
  s=${s// /$HL}
  emit '  %s%s%s%s%s' "$GRAY" "$1" "$s" "$2" "$R"
}

box_row() { # plain colored
  local pad=$(( W - 4 - ${#1} ))
  if (( pad < 0 )); then pad=0; fi
  emit '  %s%s%s %s%*s %s%s%s' "$GRAY" "$VL" "$R" "$2" "$pad" '' "$GRAY" "$VL" "$R"
}

box_pair() { # left_plain left_colored right_plain right_colored
  local gap sp
  gap=$(( W - 4 - ${#1} - ${#3} ))
  if (( gap < 1 )); then gap=1; fi
  printf -v sp '%*s' "$gap" ''
  box_row "$1$sp$3" "$2$sp$4"
}

# ── Task engine ──────────────────────────────────────────────────────────
status_line() { # emitter glyph color label duration
  local out=$1 glyph=$2 color=$3 label=$4 dur=$5 pad
  label="$(trunc "$label" $(( W - 7 - ${#dur} )))"
  pad=$(( W - 5 - ${#label} - ${#dur} ))
  if (( pad < 1 )); then pad=1; fi
  "$out" '  %s%s%s  %s%*s%s%s%s' "$color" "$glyph" "$R" "$label" "$pad" '' "$GRAY" "$dur" "$R"
}

# Animated spinner with a live tail of the command's output (runs in the background)
spinner() { # pid label t0
  local pid=$1 label=$2 t0=$3 i=0 n=${#SPIN_FRAMES[@]}
  local tail_line="" el shown gap avail pad
  while kill -0 "$pid" 2>/dev/null; do
    if (( i % 6 == 0 )); then tail_line="$(last_line)"; fi
    el="$(fmt_ms $(( $(now_ms) - t0 )))"
    shown="" gap=0
    avail=$(( W - 5 - ${#label} - ${#el} - 4 ))
    if (( avail >= 12 )) && [[ -n $tail_line ]]; then
      shown="$(trunc "$tail_line" "$avail")"
      gap=2
    fi
    pad=$(( W - 5 - ${#label} - gap - ${#shown} - ${#el} ))
    if (( pad < 1 )); then pad=1; fi
    printf '\r\033[2K  %s%s%s  %s%*s%s%s%s%*s%s%s%s' \
      "$ACCENT" "${SPIN_FRAMES[i % n]}" "$R" "$label" "$gap" '' "$DIM" "$shown" "$R" \
      "$pad" '' "$GRAY" "$el" "$R" >&3
    sleep 0.08
    i=$(( i + 1 ))
  done
}

failure_panel() { # log offset
  local line
  emit_err ''
  emit_err '  %s%s%s Last output%s' "$GRAY" "$TL" "$HL" "$R"
  while IFS= read -r line; do
    emit_err '  %s%s%s %s%s%s' "$GRAY" "$VL" "$R" "$DIM" "$(trunc "$line" $(( W - 4 )))" "$R"
  done < <(tail_since 12 "$1")
  emit_err '  %s%s%s%s' "$GRAY" "$BL" "$HL" "$R"
}

# _run <soft 0|1> <label> <command...>
_run() {
  local soft=$1 label=$2 rc=0 pid mark t0 dur
  shift 2
  label="$(trunc "$label" $(( W - 14 )))"
  mark="$(stat -c %s "$TMP_LOG")"
  t0="$(now_ms)"
  printf '\n$ %s\n' "$*"

  if (( UI_TTY )); then printf '\033[?25l' >&3; fi
  "$@" &
  pid=$!
  CHILD_PID=$pid
  if (( UI_TTY )); then
    spinner "$pid" "$label" "$t0" &
    SPIN_PID=$!
  fi

  wait "$pid" || rc=$?
  CHILD_PID=""
  if [[ -n $SPIN_PID ]]; then
    wait "$SPIN_PID" 2>/dev/null || true
    SPIN_PID=""
  fi
  if (( UI_TTY )); then printf '\r\033[2K\033[?25h' >&3; fi

  dur="$(fmt_ms $(( $(now_ms) - t0 )))"
  if (( rc == 0 )); then
    status_line emit "$S_OK" "$GREEN" "$label" "$dur"
  elif (( soft )); then
    printf '(exit status %d, continuing)\n' "$rc"
    status_line emit "$S_WARN" "$YELLOW" "$label (skipped)" "$dur"
  else
    REPORTED=1
    printf '(exit status %d)\n' "$rc"
    status_line emit_err "$S_FAIL" "$RED" "$label" "$dur"
    failure_panel "$mark"
    exit 1
  fi
  return 0
}

task() { _run 0 "$@"; }
task_soft() { _run 1 "$@"; }

# ── Lifecycle ────────────────────────────────────────────────────────────
kill_tree() {
  local pid=$1 child
  while IFS= read -r child; do
    kill_tree "$child"
  done < <(pgrep -P "$pid" 2>/dev/null || true)
  kill "$pid" 2>/dev/null || true
}

save_log() {
  {
    printf '# Umbralia %s install log\n# %s on %s (%s)\n\n' \
      "$VERSION" "$(date '+%F %T %z')" "$(uname -n)" "$(uname -sr)"
    tr '\r' '\n' <"$TMP_LOG" | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g'
  } >"$LOG_FILE" 2>/dev/null || true
}

cleanup() {
  local rc=$?
  trap - EXIT INT TERM HUP ERR
  if [[ -n $SPIN_PID ]]; then kill "$SPIN_PID" 2>/dev/null || true; fi
  if [[ -n $CHILD_PID ]]; then kill_tree "$CHILD_PID"; fi
  if [[ -n $SUDO_PID ]]; then kill "$SUDO_PID" 2>/dev/null || true; fi
  if (( UI_TTY )); then printf '\r\033[2K\033[?25h' >&3 2>/dev/null || true; fi

  if (( FINISHED == 0 )); then
    emit_err ''
    if (( rc == 130 )); then
      emit_err '  %s%s%s  Interrupted.' "$YELLOW" "$S_WARN" "$R"
    else
      if (( REPORTED == 0 )); then
        emit_err '  %s%s%s  Unexpected error%s.' "$RED" "$S_FAIL" "$R" "${ERR_LINE:+ (line $ERR_LINE)}"
      fi
      emit_err '  %s%s%s  Installation did not finish.' "$RED" "$S_FAIL" "$R"
    fi
    emit_err '     Log saved to %s' "$LOG_FILE"
    emit_err '     The installer is safe to run again.'
    emit_err ''
    save_log
  elif (( rc == 130 )); then
    emit_err ''
    emit_err '  %s%s%s  Reboot skipped. Reboot when you are ready.' "$YELLOW" "$S_WARN" "$R"
  fi
  rm -rf "$TMP_DIR"
}

on_signal() { trap - INT TERM HUP; exit "$1"; }

trap cleanup EXIT
trap 'on_signal 130' INT
trap 'on_signal 143' TERM
trap 'on_signal 129' HUP
trap 'ERR_LINE=$LINENO' ERR

# ── Install actions (run as tasks, so each is a function) ────────────────
copy_tree() { mkdir -p "$2" && cp -a "$1/." "$2/"; }

install_nvidia_rule() {
  sudo tee /etc/udev/rules.d/80-nvidia-pm.rules >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/control}="auto"
EOF
  sudo udevadm control --reload
}

build_yay() { (cd "$TMP_DIR/yay" && makepkg -si --noconfirm); }

cleanup_yay_build() {
  local reason
  rm -rf "$HOME/.cache/go" "$TMP_DIR/yay"
  # Remove go only if it was pulled in as a dependency of yay
  if pacman -Qi go >/dev/null 2>&1; then
    reason="$(pacman -Qi go | awk -F': ' '/^Install Reason/{print $2}')"
    if [[ $reason == *dependency* ]]; then
      sudo pacman -Rns --noconfirm go
    fi
  fi
}

apply_snapper_limits() {
  local cfg=$1 kv key val
  for kv in "${SNAPPER_LIMITS[@]}"; do
    key=${kv%%=*}
    val=${kv#*=}
    sudo sed -i "s/^${key}=.*/${key}=\"${val}\"/" "$cfg"
  done
}

configure_snapper_timer() {
  sudo mkdir -p /etc/systemd/system/snapper-timeline.timer.d
  sudo tee /etc/systemd/system/snapper-timeline.timer.d/override.conf >/dev/null <<'EOF'
[Timer]
OnCalendar=
OnCalendar=*-*-* 00/6:00:00
EOF
  sudo systemctl daemon-reload
  sudo systemctl restart snapper-timeline.timer
}

ensure_zdotdir() {
  if ! grep -qs 'ZDOTDIR' /etc/zsh/zshenv; then
    # shellcheck disable=SC2016
    echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv >/dev/null
  fi
}

set_login_shell() {
  local current
  current="$(getent passwd "$(id -un)" | cut -d: -f7)"
  if [[ $current != /usr/bin/zsh ]]; then
    sudo chsh -s /usr/bin/zsh "$(id -un)"
  fi
}

# ── Phases ───────────────────────────────────────────────────────────────
authenticate() {
  if ! sudo -n true 2>/dev/null; then
    sudo -v -p "  ${ACCENT}?${R}  Password for %p: " 2>&3 || die "Administrator access is required."
  fi
  pass "Administrator access granted"
  # Keep the sudo timestamp fresh until the script exits
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 55; done ) >/dev/null 2>&1 &
  SUDO_PID=$!
}

preflight() {
  local dir
  section "Pre-flight"
  if [[ $EUID -eq 0 ]]; then die "Run as your normal user, not root."; fi
  pass "Running as $(id -un)"
  command -v pacman >/dev/null 2>&1 || die "pacman not found. This installer targets Arch Linux."
  pass "Arch Linux detected"
  for dir in "$DOTFILES_DIR/home/kuro/.config" "$DOTFILES_DIR/home/kuro/.local" "$DOTFILES_DIR/etc"; do
    [[ -d $dir ]] || die "Missing directory: ${dir#"$DOTFILES_DIR"/}"
  done
  pass "Dotfiles repository is complete"
  task "Check network connectivity" curl -fsS --max-time 5 -o /dev/null https://archlinux.org
  authenticate
}

summary() {
  local i total
  finish_step
  total=$(( $(now_ms) - SCRIPT_T0 ))
  emit ''
  box_edge "$TL" "$TR"
  box_pair "$S_OK  Installation complete" "${GREEN}${B}${S_OK}  Installation complete${R}" \
    "$(fmt_ms "$total")" "${GRAY}$(fmt_ms "$total")${R}"
  box_edge "$ML" "$MR"
  for i in "${!STEP_NAMES[@]}"; do
    box_pair "$(( i + 1 ))  ${STEP_NAMES[i]}" "${ACCENT}$(( i + 1 ))${R}  ${STEP_NAMES[i]}" \
      "$(fmt_ms "${STEP_TIMES[i]}")" "${GRAY}$(fmt_ms "${STEP_TIMES[i]}")${R}"
  done
  box_edge "$BL" "$BR"
}

main() {
  SCRIPT_T0="$(now_ms)"
  if (( UI_TTY )); then clear >&3 2>/dev/null || true; fi
  banner
  sysinfo
  preflight

  step "Dotfiles $S_ARROW home"
  task "Install ~/.config" copy_tree "$DOTFILES_DIR/home/kuro/.config" "$HOME/.config"
  task "Install ~/.local" copy_tree "$DOTFILES_DIR/home/kuro/.local" "$HOME/.local"

  step "System config $S_ARROW /etc"
  task "Merge system config into /etc" sudo cp -r "$DOTFILES_DIR/etc/." /etc/
  task "Enable NVIDIA runtime power management" install_nvidia_rule
  task_soft "Refresh font cache" fc-cache -f "$HOME/.local/share/fonts"

  step "Official packages"
  if grep -q GenuineIntel /proc/cpuinfo; then UCODE=intel-ucode; else UCODE=amd-ucode; fi
  info "CPU microcode: $UCODE"
  task "Update system and install $(( ${#PACMAN_PKGS[@]} + 1 )) packages" \
    sudo pacman -Syu --needed --noconfirm "$UCODE" "${PACMAN_PKGS[@]}"

  step "yay (AUR helper)"
  if command -v yay >/dev/null 2>&1; then
    info "yay is already installed"
  else
    task "Clone yay from the AUR" git clone --depth 1 --quiet https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
    task "Build and install yay" build_yay
    task "Remove temporary build dependencies" cleanup_yay_build
  fi

  step "AUR packages"
  task "Install ${#AUR_PKGS[@]} AUR packages" \
    yay -S --needed --noconfirm --answerdiff None --answerclean None "${AUR_PKGS[@]}"

  step "Snapper tuning"
  local cfg
  for cfg in /etc/snapper/configs/root /etc/snapper/configs/home; do
    if [[ -f $cfg ]]; then
      task "Tune snapper $(basename "$cfg") config" apply_snapper_limits "$cfg"
    else
      warn "$(basename "$cfg") config not found, skipped"
    fi
  done
  if systemctl cat snapper-timeline.timer >/dev/null 2>&1; then
    task "Run snapper timeline every 6 hours" configure_snapper_timer
  else
    warn "snapper-timeline.timer not found, skipped"
  fi

  step "Services"
  task "Enable NetworkManager, bluetooth, fstrim, udisks2" \
    sudo systemctl enable --now NetworkManager bluetooth fstrim.timer udisks2
  task "Enable greetd" sudo systemctl enable greetd

  step "Zsh as default shell"
  task "Set ZDOTDIR in /etc/zsh/zshenv" ensure_zdotdir
  task "Set zsh as login shell" set_login_shell

  summary
  FINISHED=1

  if [[ -t 0 && -t 3 ]]; then
    printf '\n  Press %sEnter%s to reboot now, or %sCtrl+C%s to reboot later. ' "$B" "$R" "$B" "$R" >&3
    read -r _
    sudo reboot
  else
    emit ''
    emit '  Reboot to apply all changes.'
  fi
}

main "$@"
