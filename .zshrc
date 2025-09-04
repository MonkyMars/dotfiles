# History configuration - load early for immediate availability
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups
setopt hist_save_no_dups hist_ignore_dups hist_find_no_dups

# Shell options
setopt NO_BG_NICE NO_CLOBBER AUTO_CD CORRECT

# Environment variables - set early
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH:$HOME/go/bin"
export NVM_DIR="$HOME/.nvm"
export XDG_CURRENT_DESKTOP=Hyprland
export FILE_MANAGER=thunar
export file_manager=thunar
export XDG_SESSION_TYPE=wayland
export GTK_THEME="Adwaita:dark"
export editor="nvim"
export EDITOR="zed"
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Aliases - lightweight and frequently used
alias g='git' gs='git status' gch='git checkout' add='git add'
alias rb='reboot' pw='poweroff' c='clear' e='exit' .='cd'
alias cr='cargo run' cc='cargo check' ct='cargo test' cb='cargo build'
alias b='bun' bd='bun run dev' bi='bun install' ff='fastfetch'
alias ls='eza --all --icons --group-directories-first --color=always'
alias check='~/releases/ccheck'

# Zinit setup - defer heavy loading
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print "Installing Zinit..."
    git clone --depth=1 https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

# Essential completions - load synchronously
autoload -Uz compinit
# Speed up compinit by checking once per day
for dump in ~/.zcompdump(N.mh+24); do
    compinit
    break
done
[[ -z "$dump" ]] && compinit -C

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Key bindings
bindkey '^I' expand-or-complete
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Autosuggestions styling
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#1e3a5f'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Load plugins asynchronously for speed
zinit wait lucid for \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    OMZP::command-not-found \
    OMZP::sudo

# Load fzf-tab synchronously (needed for completions)
zinit light Aloxaf/fzf-tab

# Git plugins - load together
zinit wait lucid for \
    OMZL::git.zsh \
    OMZP::git

# Load nvmrc on startup if in a project directory (only after nvm loads)
load-nvmrc() {
    # Only run if nvm is loaded
    [[ ! $+functions[nvm] ]] && return

    local nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)"

    # Skip if same directory or no .nvmrc
    [[ "$nvmrc_path" == "$__current_nvmrc_path" ]] && return
    __current_nvmrc_path="$nvmrc_path"

    if [[ -n "$nvmrc_path" ]]; then
        local nvmrc_version="$(cat "$nvmrc_path" 2>/dev/null | tr -d '\n\r')"
        local current_version="$(nvm version 2>/dev/null || echo "none")"

        if [[ "$nvmrc_version" != "$current_version" ]]; then
            if nvm ls "$nvmrc_version" >/dev/null 2>&1; then
                nvm use "$nvmrc_version" >/dev/null 2>&1
            else
                print "Node $nvmrc_version not installed. Run: nvm install"
            fi
        fi
    fi
}

# Lazy load nvm when needed, then try to load nvmrc
lazy_load_nvm() {
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
        source "$NVM_DIR/bash_completion" 2>/dev/null
        # Remove lazy loader and replace with actual nvm
        unset -f nvm node npm npx
        source "$NVM_DIR/nvm.sh"
        # Now try to load nvmrc for current directory
        load-nvmrc
    fi
}

# Create placeholder functions that trigger lazy loading
nvm() { lazy_load_nvm; nvm "$@"; }
node() { lazy_load_nvm; node "$@"; }
npm() { lazy_load_nvm; npm "$@"; }
npx() { lazy_load_nvm; npx "$@"; }

# Add hook for directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd load-nvmrc

# Init starship and zoxide - check if installed first
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Load custom scripts if they exist
[[ -f ~/dotfiles/.zsh/usb ]] && source ~/dotfiles/.zsh/usb

# bun completions
[ -s "/home/monky/.bun/_bun" ] && source "/home/monky/.bun/_bun"
