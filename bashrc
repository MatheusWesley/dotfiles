# ~/.bashrc

# Starship
eval "$(starship init bash)"

# FZF
eval "$(fzf --bash)"

# -----------------------------------------------------
# Aliases
# -----------------------------------------------------
# Comandos para terminal e gerenciamento de diretórios
alias zx='clear'
alias l='exa -l --icons'
alias ls='exa -a --icons'
alias ll='exa -al --icons'
alias lt='exa -a --tree --level=1 --icons'
alias x='exit'
alias shutdown='systemctl poweroff'
alias v='$EDITOR'

alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

. "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CONFIG_DIRS="/etc/xdg"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

PATH=~/.console-ninja/.bin:$PATH

