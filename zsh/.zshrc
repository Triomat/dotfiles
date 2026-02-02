# ~/.zshrc

#===========================================
# Environment Variables
#===========================================
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"

# Path configuration
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# History configuration
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

#===========================================
# Aliases - General
#===========================================
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Safe operations
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

#===========================================
# Aliases - Infrastructure & DevOps
#===========================================
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias tf='terraform'
alias tg='terragrunt'
alias dc='docker-compose'
alias dps='docker ps'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'

# Ansible shortcuts
alias ap='ansible-playbook'
alias av='ansible-vault'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

#===========================================
# Functions
#===========================================
# SSH to homelab hosts with tmux
ssht() {
    ssh -t "$1" "tmux attach || tmux new"
}

# Quick kubectl context switch
kctx() {
    kubectl config use-context "$1"
}

# Quick directory navigation to common paths
cdp() {
    cd ~/projects/"$1"
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

#===========================================
# Prompt Configuration
#===========================================
# Simple two-line prompt with user@host and path
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f
%# '

# Right prompt with time
RPROMPT='%F{gray}%*%f'

#===========================================
# Completion
#===========================================
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Kubectl completion (if installed)
[[ -x $(command -v kubectl) ]] && source <(kubectl completion zsh)

#===========================================
# Key Bindings
#===========================================
# Emacs-style keybindings (default)
bindkey -e

# Ctrl+arrow keys for word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

#===========================================
# Local Customizations
#===========================================
# Source local config if exists (for machine-specific settings)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
