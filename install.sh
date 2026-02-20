#!/usr/bin/env bash
set -euo pipefail

# Install zsh if missing — explicit error handling because set -e is
# disabled inside `if !` bodies in bash.
if ! command -v zsh &>/dev/null; then
  echo "Installing zsh..."
  if [[ $EUID -eq 0 ]] && command -v apt-get &>/dev/null; then
    apt-get update -qq || { echo "Error: apt-get update failed" >&2; exit 1; }
    apt-get install -y zsh || { echo "Error: failed to install zsh" >&2; exit 1; }
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -qq || { echo "Error: sudo apt-get update failed" >&2; exit 1; }
    sudo apt-get install -y zsh || { echo "Error: failed to install zsh via sudo" >&2; exit 1; }
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm zsh || { echo "Error: failed to install zsh" >&2; exit 1; }
  elif command -v brew &>/dev/null; then
    brew install zsh || { echo "Error: failed to install zsh" >&2; exit 1; }
  else
    echo "Error: cannot install zsh automatically. Run: sudo apt-get install -y zsh" >&2
    exit 1
  fi
  command -v zsh &>/dev/null || { echo "Error: zsh not found after install" >&2; exit 1; }
fi

# Oh My Zsh (skip if already installed)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
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

# Clone and stow dotfiles
DOTFILES_DIR="$HOME/.dotfiles"
REPO="https://github.com/Triomat/dotfiles.git"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone "$REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Install stow if missing
if ! command -v stow &>/dev/null; then
  if [[ $EUID -eq 0 ]] && command -v apt-get &>/dev/null; then
    apt-get install -y stow || { echo "Error: failed to install stow" >&2; exit 1; }
  elif command -v apt-get &>/dev/null; then
    sudo apt-get install -y stow || { echo "Error: failed to install stow" >&2; exit 1; }
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm stow || { echo "Error: failed to install stow" >&2; exit 1; }
  elif command -v brew &>/dev/null; then
    brew install stow || { echo "Error: failed to install stow" >&2; exit 1; }
  else
    echo "Error: cannot install stow automatically." >&2
    exit 1
  fi
fi

# Backup existing files that would conflict
[[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak"

stow -v --target="$HOME" zsh

echo "Done! Run: exec zsh"
