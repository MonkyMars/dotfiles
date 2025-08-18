# Save history immediately after each command
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt NO_BG_NICE
setopt NO_CLOBBER
setopt AUTO_CD
setopt CORRECT

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Init starship and zoxide
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# Powerful aliases that I use commonly
alias langsort='~/Coding/golang/LangSort/./filesorting'
alias g='git'
alias gs='git status'
alias gm='git commit -m'
alias pw='poweroff'
alias c='clear'
alias cr='cargo run'
alias cc='cargo check'
alias rb='reboot'
alias ff='fastfetch'
alias ls='eza --all --icons --group-directories-first --color=always'

autoload -Uz compinit
compinit

# Source nvm
source /usr/share/nvm/init-nvm.sh

autoload -U add-zsh-hook

# Load the node version of the .nvmrc when loaded into the directory for fast switching
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(cat "$nvmrc_path" | tr -d '\n\r')

    if [ "$nvmrc_node_version" != "$node_version" ]; then
      if ! nvm ls "$nvmrc_node_version" >/dev/null 2>&1; then
        echo "Node version $nvmrc_node_version not installed. Installing..."
        nvm install "$nvmrc_node_version"
      fi
      nvm use "$nvmrc_node_version"
    fi
  fi
}

# Add the hook and load the function
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Set autosuggestions styling
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#1e3a5f'
typeset -A ZSH_HIGHLIGHT_STYLES

# Load custom USB script
source ~/.zsh/usb

# Zinit Bootstrap
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  echo "Installing Zinit..."
  git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Snippets
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::command-not-found
zinit cdreplay -q
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo

# Keybinds
bindkey '^I' expand-or-complete
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Completetions
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

# Load syntax highlighting and autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions

# Export path so it is available in my shell
export PATH=$HOME/.local/bin:$PATH
