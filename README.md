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

## Prerequisites

Just run `./bootstrap.sh` — it will install GNU Stow and Oh My Zsh if they’re missing.  
On macOS, you need [Homebrew](https://brew.sh/) installed first.  
On Linux, make sure you have `git` and a package manager that can install `stow`.
