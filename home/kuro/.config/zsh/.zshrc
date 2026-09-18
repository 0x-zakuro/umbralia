# --- 1. Basic Options ---
autoload -U compinit; compinit  # Enables the advanced tab completion system
setopt correct                  # Auto-corrects minor spelling mistakes (sl -> ls)

# --- 2. History (The Memory) ---
HISTFILE=~/.zsh_history         # Where to save your command history
HISTSIZE=1000           # How many commands to remember in the current session
SAVEHIST=1000           # How many commands to save to the file
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
fastfetch

export EDITOR=nvim

clean() {
    clear
    echo -e "\n \e[1;34m◆ SYSTEM CLEANUP \e[0m"
    echo -e " \e[1;30m──────────────────────────────────────────\e[0m"

    sudo -v

    echo -e "\n \e[1;37m[1/5] \e[1;36mPACKAGES  \e[1;30m▶\e[0m Clearing orphans & old package cache..."
    yay -Yc --noconfirm >/dev/null 2>&1
    if command -v paccache &> /dev/null; then
        sudo paccache -rk2 >/dev/null 2>&1
        sudo paccache -ruk0 >/dev/null 2>&1
    fi

    echo -e " \e[1;37m[2/5] \e[1;36mFLATPAK   \e[1;30m▶\e[0m Clearing unused runtimes..."
    if command -v flatpak &> /dev/null; then
        flatpak uninstall --unused --noninteractive >/dev/null 2>&1
    fi

    echo -e " \e[1;37m[3/5] \e[1;36mLOGS      \e[1;30m▶\e[0m Vacuuming journals (3d)..."
    sudo journalctl --vacuum-time=3d >/dev/null 2>&1
    journalctl --user --vacuum-time=3d >/dev/null 2>&1

    echo -e " \e[1;37m[4/5] \e[1;36mTRASH     \e[1;36m▶\e[0m Emptying coredumps & trash..."
    sudo find /var/lib/systemd/coredump/ -type f -delete 2>/dev/null
    rm -rf ~/.local/share/Trash/files ~/.local/share/Trash/info
    mkdir -p ~/.local/share/Trash/{files,info}

    echo -e " \e[1;37m[5/5] \e[1;36mDEV CACHE \e[1;30m▶\e[0m Purging build caches..."
    rm -rf ~/.cache/yay/* 2>/dev/null
    rm -rf ~/.cache/pip/* 2>/dev/null
    rm -rf ~/.npm/_cacache/* 2>/dev/null
    if command -v go &> /dev/null; then
        go clean -modcache >/dev/null 2>&1
    fi

    echo -e "\n \e[1;32m✔ CLEANUP COMPLETE \e[1;30m| \e[1;37m$(date +%H:%M:%S)\e[0m\n"
}
