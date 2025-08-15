# Dotfiles

My personal configuration files for **Zsh**, **Neovim**, and **Git**.  
Managed with [GNU Stow](https://www.gnu.org/software/stow/) to keep everything version-controlled and easy to set up on new machines.

---

## Features

- Keeps configs in `~/.dotfiles` but symlinks them back into `$HOME`
- Clean separation: `zsh/`, `nvim/`, `git/`
- Ignores runtime files like history and caches
- Portable: works on macOS and Linux

---

## Prerequisites

### macOS
Install [Homebrew](https://brew.sh/) if you don’t already have it:

```sh
command -v brew >/dev/null 2>&1 || \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
