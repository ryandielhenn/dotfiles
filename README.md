# Dotfiles

My personal configuration files for **Zsh**, **Neovim**, and **Git**.  
Managed with [GNU Stow](https://www.gnu.org/software/stow/) to keep everything version-controlled and easy to set up on new machines.

---

## Features

- Keep configs in `~/.dotfiles`, `./bootstrap.sh` symlinks them back into `$HOME`
- Clean separation: `zsh/`, `nvim/`, `git/`
- Ignores runtime files like history and caches
- Portable: works on macOS and Linux

---

## Prerequisites

Just run `./bootstrap.sh` — it will install GNU Stow and Oh My Zsh if they’re missing.  
On macOS, you need [Homebrew](https://brew.sh/) installed first.  
On Linux, make sure you have `git` and a package manager that can install `stow`.

---

## Usage

```text
Usage: ./bootstrap.sh [options]

Options:
  --dry-run        Show what would happen without making changes
  --no-ohmyzsh     Skip installing Oh My Zsh
  --chsh           Switch your default shell to zsh (using chsh)
  --packages ...   Space-separated list of subfolders to stow (defaults: zsh nvim git)

Examples:
  ./bootstrap.sh
      # Run normally, stowing default packages and installing Oh My Zsh

  ./bootstrap.sh --dry-run
      # Show which files would be symlinked without actually making changes

  ./bootstrap.sh --no-ohmyzsh
      # Run but skip installing Oh My Zsh

  ./bootstrap.sh --packages zsh git
      # Only stow zsh and git configs (skip nvim)

### Neovim + CoC Setup (Linux)

To get `coc.nvim` working properly, you need a recent version of Vim/Neovim, a plugin manager, and Node.js (used by CoC for language servers).

```bash
# --- Install latest Neovim ---
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install -y neovim

# (Optional) Install a modern Vim as fallback
sudo add-apt-repository ppa:jonathonf/vim -y
sudo apt update
sudo apt install -y vim

# --- Install vim-plug (plugin manager) ---
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# --- Install Node.js (LTS) ---
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# --- Install CoC plugins after starting nvim ---
nvim +'PlugInstall --sync' +qa
nvim +'CocInstall -sync coc-json coc-tsserver' +qa
