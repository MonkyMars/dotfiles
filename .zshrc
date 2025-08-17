# Save history immediately after each command
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt NO_BG_NICE
setopt NO_CLOBBER
setopt AUTO_CD
setopt CORRECT

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

fdall() {
  sudo fd "$@" / 2>/dev/null
}

alias langsort='~/Coding/golang/LangSort/./filesorting'
alias g='git'
alias pw='poweroff'
alias ls='eza --all --icons'
alias ff='fastfetch'

autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
bindkey '^I' expand-or-complete

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

autoload -U add-zsh-hook
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
add-zsh-hook chpwd load-nvmrc
load-nvmrc

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#1e3a5f'

typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold


source /usr/share/nvm/init-nvm.sh

# Load custom USB script
# source ~/.zsh/usb

# Zinit Bootstrap
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  echo "Installing Zinit..."
  git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust
export PATH=$HOME/.local/bin:$PATH

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
