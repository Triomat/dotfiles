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
# fzf
if ! command -v fzf &>/dev/null; then
  echo "Installing fzf..."
  if command -v apt-get &>/dev/null; then
    if [[ $EUID -eq 0 ]]; then
      apt-get install -y fzf || { echo "Error: failed to install fzf" >&2; exit 1; }
    else
      sudo apt-get install -y fzf || { echo "Error: failed to install fzf via sudo" >&2; exit 1; }
    fi
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm fzf || { echo "Error: failed to install fzf" >&2; exit 1; }
  elif command -v brew &>/dev/null; then
    brew install fzf || { echo "Error: failed to install fzf" >&2; exit 1; }
  else
    git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-update-rc \
      || { echo "Error: fzf install script failed" >&2; exit 1; }
  fi
  command -v fzf &>/dev/null || { echo "Error: fzf not found after install" >&2; exit 1; }
fi

# Resolve FZF_BASE for the oh-my-zsh fzf plugin
if [[ -d "$HOME/.fzf" ]]; then
  export FZF_BASE="$HOME/.fzf"
elif command -v brew &>/dev/null && brew --prefix fzf &>/dev/null 2>&1; then
  export FZF_BASE="$(brew --prefix fzf)"
elif [[ -d /usr/share/fzf ]]; then
  export FZF_BASE=/usr/share/fzf
else
  FZF_BIN="$(command -v fzf)"
  export FZF_BASE="$(dirname "$(dirname "$FZF_BIN")")"
fi
echo "FZF_BASE set to: $FZF_BASE"
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
