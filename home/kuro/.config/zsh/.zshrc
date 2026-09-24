# --- 1. Basic Options ---
autoload -U compinit; compinit  # Enables the advanced tab completion system
setopt correct                  # Auto-corrects minor spelling mistakes (sl -> ls)

# --- 2. History (The Memory) ---
HISTFILE=~/.zsh_history         # Where to save your command history
HISTSIZE=10000                  # How many commands to remember in the current session
SAVEHIST=10000                  # How many commands to save to the file
setopt HIST_IGNORE_DUPS         # Don't record the same command twice in a row

# --- 3. The Plugins (Visuals & Speed) ---
# Load the packages we just installed with pacman
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- 6. Visual Tab Completion (The Menu) ---
# This makes the Tab key show a selectable menu with colors
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# --- 4. Your Visuals ---
eval "$(starship init zsh)"

# --- 5. Cleanup Script ---
cleanup() {
    emulate -L zsh
    setopt local_options rm_star_silent null_glob
    local start_time=$(date +%s)
    local errors=0

    print() { echo "  $1" }
    step() { echo "\n[$1] $2" }

    echo "System Cleanup — $(date '+%Y-%m-%d %H:%M')"
    echo "────────────────────────────────────────"

    sudo -v

    step "1/7" "System update"
    if command -v yay &>/dev/null; then
        yay -Syu --noconfirm || ((errors++))
    else
        sudo pacman -Syu --noconfirm || ((errors++))
    fi

    step "2/7" "Pacman cache + orphans"
    command -v paccache &>/dev/null || sudo pacman -S --needed pacman-contrib
    sudo paccache -rk2 || ((errors++))
    sudo paccache -ruk0 || ((errors++))
    local orphans=$(pacman -Qdtq 2>/dev/null)
    if [[ -n "$orphans" ]]; then
        sudo pacman -Rns --noconfirm $(pacman -Qdtq) || ((errors++))
        print "removed: $(wc -l <<< "$orphans") orphan package(s)"
    else
        print "no orphans found"
    fi

    step "3/7" "Flatpak runtimes"
    if command -v flatpak &>/dev/null; then
        flatpak uninstall --unused --noninteractive || ((errors++))
    else
        print "flatpak not installed, skipped"
    fi

    step "4/7" "Journal logs"
    sudo journalctl --vacuum-time=7d &>/dev/null || ((errors++))
    journalctl --user --vacuum-time=7d &>/dev/null || ((errors++))

    step "5/7" "Coredumps + trash"
    sudo find /var/lib/systemd/coredump/ -type f -delete 2>/dev/null
    rm -rf ~/.local/share/Trash/files/* ~/.local/share/Trash/info/* 2>/dev/null

    step "6/7" "Dev tool caches"
    rm -rf ~/.cache/yay/* ~/.cache/pip/* ~/.npm/_cacache/* 2>/dev/null
    if command -v go &>/dev/null; then
        go clean -cache &>/dev/null
    fi

    step "7/7" "Home cache"
    print "~/.cache is $(du -sh ~/.cache 2>/dev/null | cut -f1)"

    local elapsed=$(( $(date +%s) - start_time ))

    echo "\n────────────────────────────────────────"
    if (( errors == 0 )); then
        echo "Done in ${elapsed}s"
    else
        echo "Done in ${elapsed}s with ${errors} error(s)"
    fi
}