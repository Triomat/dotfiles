# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's included

- **zsh** — Oh My Zsh + Powerlevel10k + autosuggestions + syntax highlighting
- **tmux** — Catppuccin themed status bar + TPM

## One-liner install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Triomat/dotfiles/main/install.sh)
```

## Post-install
```bash
exec zsh          # reload shell
p10k configure    # configure prompt (optional)
```

## Manual stow usage
```bash
cd ~/.dotfiles
stow -v --target="$HOME" zsh tmux
```
