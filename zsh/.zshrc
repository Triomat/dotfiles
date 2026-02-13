# ~/.zshrc - ZSH Configuration with Oh-My-Zsh

# Enable Powerlevel10k instant prompt (must be at the very top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

#===========================================
# Oh-My-Zsh Theme
#===========================================
ZSH_THEME="powerlevel10k/powerlevel10k"

#===========================================
# Oh-My-Zsh Plugins
#===========================================
plugins=(
    git
    docker
    docker-compose
    kubectl
    terraform
    ansible
    tmux
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    command-not-found
    sudo
)

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

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
# FZF Configuration
#===========================================
# Source fzf key bindings and completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FZF default options
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --preview-window=:hidden
  --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | head -200))'
  --bind='?:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty)'
"

# Use fd instead of find if available
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# Use rg for faster searching if available
if command -v rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
fi

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

# Editor aliases
alias vim='nvim'
alias vi='nvim'

#===========================================
# Aliases - Infrastructure & DevOps
#===========================================
# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kl='kubectl logs'
alias kx='kubectl exec -it'

# Terraform/OpenTofu
alias tf='terraform'
alias tg='terragrunt'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# Docker
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'
alias dex='docker exec -it'

# Ansible shortcuts
alias ap='ansible-playbook'
alias av='ansible-vault'
alias ai='ansible-inventory'

# Git shortcuts (Oh-My-Zsh git plugin provides many, but here are extras)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gpl='git pull'

#===========================================
# Functions
#===========================================
ssm() {
    ~/.ssh/ssh-menu.sh
}

# SSH to homelab hosts with tmux
ssht() {
    ssh -t "$1" "tmux attach || tmux new"
}

# Quick kubectl context switch
kctx() {
    kubectl config use-context "$1"
}

# Quick kubectl namespace switch
kns() {
    kubectl config set-context --current --namespace="$1"
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
# FZF-powered Functions
#===========================================

# Interactive kubectl pod selection
kpod() {
    local pod=$(kubectl get pods --all-namespaces -o wide | fzf --header-lines=1 | awk '{print $2, $1}')
    if [[ -n $pod ]]; then
        local pod_name=$(echo $pod | awk '{print $1}')
        local namespace=$(echo $pod | awk '{print $2}')
        echo "Selected: $pod_name in namespace $namespace"
        kubectl --namespace=$namespace "$@" $pod_name
    fi
}

# Interactive kubectl logs
klogs() {
    local pod=$(kubectl get pods --all-namespaces -o wide | fzf --header-lines=1 | awk '{print $2, $1}')
    if [[ -n $pod ]]; then
        local pod_name=$(echo $pod | awk '{print $1}')
        local namespace=$(echo $pod | awk '{print $2}')
        kubectl --namespace=$namespace logs -f $pod_name
    fi
}

# Interactive kubectl exec
kexec() {
    local pod=$(kubectl get pods --all-namespaces -o wide | fzf --header-lines=1 | awk '{print $2, $1}')
    if [[ -n $pod ]]; then
        local pod_name=$(echo $pod | awk '{print $1}')
        local namespace=$(echo $pod | awk '{print $2}')
        kubectl --namespace=$namespace exec -it $pod_name -- ${1:-bash}
    fi
}

# Interactive git branch checkout
fgb() {
    git branch -a | grep -v HEAD | sed 's/remotes\/origin\///' | sort -u | fzf --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -200' | sed 's/^..//' | awk '{print $1}' | xargs git checkout
}

# Interactive git log browser
fgl() {
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" | fzf --ansi --no-sort --reverse --tiebreak=index --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}' --bind "ctrl-m:execute:(grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
    {}
FZF-EOF"
}

# Interactive process killer
fkill() {
    local pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
        echo $pid | xargs kill -${1:-9}
    fi
}

# SSH with fzf selection from SSH config
fssh() {
    local selected_host=$(grep "^Host " ~/.ssh/config 2>/dev/null | grep -v '\*' | awk '{print $2}' | fzf --preview 'grep -A 10 "^Host {}" ~/.ssh/config')
    if [[ -n $selected_host ]]; then
        ssh "$selected_host"
    fi
}

# Docker container selection and exec
fdocker() {
    local container=$(docker ps --format '{{.Names}}' | fzf)
    if [[ -n $container ]]; then
        docker exec -it "$container" "${1:-bash}"
    fi
}

# Ansible inventory host selection
fansible() {
    local host=$(ansible-inventory --list 2>/dev/null | jq -r '.[]._meta.hostvars | keys[]' 2>/dev/null | sort -u | fzf)
    if [[ -n $host ]]; then
        echo "$host"
    fi
}

# Interactive Proxmox VM selection (if you have pvesh/qm access)
fproxmox() {
    local vm=$(qm list 2>/dev/null | tail -n +2 | fzf | awk '{print $1}')
    if [[ -n $vm ]]; then
        echo "Selected VM: $vm"
        qm "$@" $vm
    fi
}

#===========================================
# Completions
#===========================================
# Case-insensitive completion (Oh-My-Zsh handles most of this)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Kubectl completion (if not already loaded by plugin)
[[ -x $(command -v kubectl) ]] && source <(kubectl completion zsh)

#===========================================
# Custom Plugin Configurations
#===========================================
# zsh-autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# tmux plugin
ZSH_TMUX_AUTOSTART=false
ZSH_TMUX_AUTOCONNECT=false

#===========================================
# Syntax Highlighting (if installed manually)
#===========================================
# Source zsh-syntax-highlighting if installed in home directory
[ -f ~/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source ~/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#===========================================
# Powerlevel10k Configuration
#===========================================
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#===========================================
# Local Customizations
#===========================================
# Source local config if exists (for machine-specific settings)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
