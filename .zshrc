
# ── History ──────────────────────────────────────────────────────
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=5000
SAVEHIST=5000

setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS

# ── Shell options ────────────────────────────────────────────────
setopt NO_BG_NICE NO_CLOBBER AUTO_CD CORRECT

# ── Environment ──────────────────────────────────────────────────
export FILE_MANAGER=thunar
export file_manager=thunar
export EDITOR="zeditor --wait"
export VISUAL="$EDITOR"

export BUN_INSTALL="$HOME/.bun"
export VOLTA_HOME="$HOME/.volta"
export GOENV_ROOT="$HOME/.goenv"
export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"

typeset -U path PATH
path=(
    "$BUN_INSTALL/bin"
    "$VOLTA_HOME/bin"
    "$HOME/.local/bin"
    "$CARGO_HOME/bin"
    "$GOENV_ROOT/bin"
    "$HOME/go/bin"
    "$HOME/.spicetify"
    "$HOME/.opencode/bin"
    $path
)

# ── Aliases ──────────────────────────────────────────────────────
alias g='git' gs='git status' gsw='git switch'
alias add='git add' gc='git commit -m'
alias gp='git push -u origin' gl='git pull' gst='git stash'

alias rb='reboot' pw='poweroff' c='clear' e='exit' m='mkdir'
alias gr='go run' gb='go build' gt='go test' gfmt='gofmt -w .'
alias cr='cargo run' cc='cargo check' ct='cargo test' cb='cargo build'

alias b='bun' bd='bun run dev' bi='bun install' ff='fastfetch'
alias ls='eza --all --icons=auto --group-directories-first --color=auto'

alias dc='docker compose up --build'
alias ddev='docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build'
alias dprod='docker compose up -d --build'
alias dp='docker ps -sa'
alias dr='docker run -t'

alias py='python3' pyr='python3 main.py'
alias zed='zeditor'
alias check='ccheck'

# ── Zinit ────────────────────────────────────────────────────────
ZINIT_HOME="${ZDOTDIR:-$HOME}/.local/share/zinit/zinit.git"

if [[ ! -r "$ZINIT_HOME/zinit.zsh" ]]; then
    if (( $+commands[git] )); then
        command git clone --depth=1 \
            https://github.com/zdharma-continuum/zinit.git \
            "$ZINIT_HOME" || return 1
    else
        print -u2 "Zinit requires git."
        return 1
    fi
fi

source "$ZINIT_HOME/zinit.zsh"

# ── Completion cache ────────────────────────────────────────────
autoload -Uz compinit

# Rebuild at most once per day; use the fast cached path otherwise.
if [[ ! -f "${ZDOTDIR:-$HOME}/.zcompdump" ||
      "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# ── Carapace ─────────────────────────────────────────────────────
if (( $+commands[carapace] )); then
    export CARAPACE_BRIDGES='zsh,fish,bash'
    source <(carapace _carapace)
fi

# ── Completion styling ──────────────────────────────────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ── Key bindings ─────────────────────────────────────────────────
bindkey '^I' expand-or-complete
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward

# ── Plugins ──────────────────────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#1e3a5f'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Defer plugins that aren't needed to initialize the prompt.
zinit wait lucid for \
    atload'_zsh_autosuggest_start' \
        zsh-users/zsh-autosuggestions \
    OMZP::command-not-found \
    OMZP::sudo

# Completion widget integration must follow compinit.
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use

# Load highlighting after widgets and other plugins.
zinit light zdharma-continuum/fast-syntax-highlighting

# ── Prompt and navigation ────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# ── History search ───────────────────────────────────────────────
(( $+commands[atuin] )) && eval "$(atuin init zsh)"

# ── Go environment ───────────────────────────────────────────────
(( $+commands[goenv] )) && eval "$(goenv init - zsh)"

# ── Optional scripts ─────────────────────────────────────────────
[[ -f "$HOME/dotfiles/.zsh/usb" ]] &&
    source "$HOME/dotfiles/.zsh/usb"

[[ -s "$BUN_INSTALL/_bun" ]] &&
    source "$BUN_INSTALL/_bun"
