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
export XDG_CURRENT_DESKTOP=Hyprland
export FILE_MANAGER=thunar
export file_manager=thunar
export XDG_SESSION_TYPE=wayland
export GTK_THEME="Adwaita:dark"
export editor="nvim"
export EDITOR="zed"
export GOENV_AUTOMATICALLY_DETECT_VERSION=1
export BUN_INSTALL="$HOME/.bun"
export VOLTA_HOME="$HOME/.volta"
export GOENV_ROOT="$HOME/.goenv"
export CARGO_ROOT="$HOME/.cargo"
export PATH="$BUN_INSTALL/bin:$VOLTA_HOME/bin:$HOME/.local/bin:$CARGO_ROOT/bin:$GOENV_ROOT/bin:$PATH"

# Aliases - lightweight and frequently used
alias g='git' gs='git status' gsw='git switch' add='git add' gc='git commit -m'
alias gp='git push -u origin' gl='git pull' gst='git stash'
alias rb='reboot' pw='poweroff' c='clear' e='exit'
alias gr='go run' gb='go build' gt='go test' gfmt='gofmt -w .'
alias cr='cargo run' cc='cargo check' ct='cargo test' cb='cargo build'
alias b='bun' bd='bun run dev' bi='bun install' ff='fastfetch'
alias ls='eza --all --icons --group-directories-first --color=always'
alias dc='docker-compose up --build'
alias dp='docker ps -sa'
alias dr='docker run -t'
alias py='python3' pyr='python3 main.py'

zedf () {
    dir="$(zoxide query -i)"
    zed "$dir"
}

# https://github.com/MonkyMars/ccheck
alias check='ccheck'

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

# Load fzf history search plugin
zinit light joshskidmore/zsh-fzf-history-search

# Load zsh-you-should-use plugin - Warns if you use a command that has an alias
zinit light MichaelAquilina/zsh-you-should-use

# Add hook for directory changes
autoload -U add-zsh-hook

# Init starship and zoxide - check if installed first
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

if command -v goenv >/dev/null 2>&1; then
    eval "$(goenv init - zsh)"
fi

# Load custom scripts if they exist
[[ -f ~/dotfiles/.zsh/usb ]] && source ~/dotfiles/.zsh/usb

# bun completions
[ -s "/home/monky/.bun/_bun" ] && source "/home/monky/.bun/_bun"

[[ -f ~/.zshrc.zwc ]] || zcompile ~/.zshrc
