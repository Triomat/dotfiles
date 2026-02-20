#!/usr/bin/env bash
set -euo pipefail

# Install zsh if missing
if ! command -v zsh &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y zsh
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm zsh
  elif command -v brew &>/dev/null; then
    brew install zsh
  else
    echo "Cannot install zsh: no supported package manager found." >&2
    exit 1
  fi
fi

# Oh My Zsh (skip if already installed)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattach
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Plugins
declare -A plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

for plugin in "${!plugins[@]}"; do
  [[ -d "$ZSH_CUSTOM/plugins/$plugin" ]] || \
    git clone --depth=1 "${plugins[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin"
done

# Theme
[[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# Clone and stow dotfiles (adjust repo URL)
DOTFILES_DIR="$HOME/.dotfiles"
REPO="https://github.com/Triomat/dotfiles.git"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone "$REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"
# Install stow if missing
command -v stow &>/dev/null || {
  sudo apt-get update && sudo apt-get install -y stow 2>/dev/null || \
  sudo pacman -S --noconfirm stow 2>/dev/null || \
  brew install stow 2>/dev/null
}

# Backup existing files that would conflict
[[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak"

stow -v --target="$HOME" zsh  # adjust package name to your stow structure

echo "Done! Run: exec zsh"
