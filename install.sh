#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install.sh — Raphael's dotfiles bootstrap
# Installs: zsh, oh-my-zsh, plugins, powerlevel10k, fzf, neovim, vim-plug
# Clones dotfiles and stows: zsh, nvim
# =============================================================================

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
has() { command -v "$1" &>/dev/null; }

pkg_install() {
  # Usage: pkg_install <package> [<package> ...]
  if [[ $EUID -eq 0 ]] && has apt-get; then
    apt-get install -y "$@" || { echo "Error: failed to install $*" >&2; exit 1; }
  elif has apt-get; then
    sudo apt-get install -y "$@" || { echo "Error: failed to install $*" >&2; exit 1; }
  elif has pacman; then
    sudo pacman -S --noconfirm "$@" || { echo "Error: failed to install $*" >&2; exit 1; }
  elif has brew; then
    brew install "$@" || { echo "Error: failed to install $*" >&2; exit 1; }
  else
    echo "Error: no supported package manager found to install $*" >&2
    exit 1
  fi
}

apt_update() {
  if [[ $EUID -eq 0 ]] && has apt-get; then
    apt-get update -qq || { echo "Error: apt-get update failed" >&2; exit 1; }
  elif has apt-get; then
    sudo apt-get update -qq || { echo "Error: apt-get update failed" >&2; exit 1; }
  fi
}

# -----------------------------------------------------------------------------
# zsh
# -----------------------------------------------------------------------------
if ! has zsh; then
  echo "Installing zsh..."
  if has apt-get; then apt_update; fi
  pkg_install zsh
  has zsh || { echo "Error: zsh not found after install" >&2; exit 1; }
fi

# -----------------------------------------------------------------------------
# Oh My Zsh
# -----------------------------------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# -----------------------------------------------------------------------------
# Oh My Zsh plugins
# -----------------------------------------------------------------------------
declare -A omz_plugins=(
  [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions.git"
  [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
)
for plugin in "${!omz_plugins[@]}"; do
  if [[ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
    echo "Cloning $plugin..."
    git clone --depth=1 "${omz_plugins[$plugin]}" "$ZSH_CUSTOM/plugins/$plugin"
  fi
done

# -----------------------------------------------------------------------------
# Powerlevel10k theme
# -----------------------------------------------------------------------------
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  echo "Cloning powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# -----------------------------------------------------------------------------
# fzf
# -----------------------------------------------------------------------------
if ! has fzf; then
  echo "Installing fzf..."
  if has apt-get; then
    apt_update
    pkg_install fzf
  elif has pacman; then
    pkg_install fzf
  elif has brew; then
    pkg_install fzf
  else
    # Fallback: upstream git install (no root needed)
    git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all --no-update-rc \
      || { echo "Error: fzf install script failed" >&2; exit 1; }
  fi
  has fzf || { echo "Error: fzf not found after install" >&2; exit 1; }
fi

# Resolve FZF_BASE for the oh-my-zsh fzf plugin
if [[ -d "$HOME/.fzf" ]]; then
  export FZF_BASE="$HOME/.fzf"
elif has brew && brew --prefix fzf &>/dev/null 2>&1; then
  export FZF_BASE="$(brew --prefix fzf)"
elif [[ -d /usr/share/fzf ]]; then
  export FZF_BASE=/usr/share/fzf
else
  FZF_BIN="$(command -v fzf)"
  export FZF_BASE="$(dirname "$(dirname "$FZF_BIN")")"
fi
echo "FZF_BASE set to: $FZF_BASE"

# -----------------------------------------------------------------------------
# Neovim
# -----------------------------------------------------------------------------
install_nvim() {
  local install_dir="$HOME/.local/nvim"
  mkdir -p "$install_dir"

  if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
    echo "Downloading neovim (latest stable)..."
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    curl -fsSL "$url" | tar -xz -C "$install_dir" --strip-components=1 \
      || { echo "Error: failed to download/extract neovim" >&2; exit 1; }
    if [[ $EUID -eq 0 ]]; then
      ln -sf "$install_dir/bin/nvim" /usr/local/bin/nvim
    else
      mkdir -p "$HOME/.local/bin"
      ln -sf "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"
      export PATH="$HOME/.local/bin:$PATH"
    fi
  elif has brew; then
    pkg_install neovim
  elif has pacman; then
    pkg_install neovim
  else
    echo "Error: cannot auto-install neovim on this platform. Install manually." >&2
    exit 1
  fi
}

if ! has nvim; then
  echo "Installing neovim..."
  install_nvim
  has nvim || { echo "Error: nvim not found after install" >&2; exit 1; }
fi

# vim-plug for Neovim
VIM_PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [[ ! -f "$VIM_PLUG_PATH" ]]; then
  echo "Installing vim-plug..."
  curl -fLo "$VIM_PLUG_PATH" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    || { echo "Error: failed to install vim-plug" >&2; exit 1; }
fi

# -----------------------------------------------------------------------------
# stow
# -----------------------------------------------------------------------------
if ! has stow; then
  echo "Installing stow..."
  pkg_install stow
fi

# -----------------------------------------------------------------------------
# Dotfiles
# -----------------------------------------------------------------------------
DOTFILES_DIR="$HOME/.dotfiles"
REPO="https://github.com/Triomat/dotfiles.git"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  echo "Cloning dotfiles..."
  git clone "$REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Backup any real files that would conflict with stow
backup_if_real() {
  local f="$1"
  [[ -e "$f" && ! -L "$f" ]] && mv "$f" "${f}.bak" && echo "Backed up ${f} → ${f}.bak"
}

backup_if_real "$HOME/.zshrc"
backup_if_real "$HOME/.config/nvim/init.vim"

# Stow all managed packages
echo "Stowing dotfiles..."
stow -v --target="$HOME" zsh nvim

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. exec zsh                          — switch to zsh"
echo "  2. nvim +PlugInstall +qall           — install nvim plugins"
echo "  3. nvim +'TSUpdate' +qall            — fetch treesitter grammars"
echo "  4. Install LSP servers as needed:"
echo "       pip install pyright"
echo "       npm i -g bash-language-server yaml-language-server"
