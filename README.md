# Dotfiles

My personal configuration files.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) to keep everything easy to set up on new machines.

---

## Features

- Keep configs in `~/.dotfiles`, `python3 scripts/bootstrap.py` symlinks them back into `$HOME`
- Clean separation: `zsh/`, `nvim/`, `git/`, `alacritty/`, etc.
- Ignores runtime files like history and caches
- Portable: works on macOS, Linux, Windows

---

## Prerequisites

Just run `python3 scripts/bootstrap.py` — it will install GNU Stow and Oh My Zsh if they’re missing.  
On macOS, you need [Homebrew](https://brew.sh/) installed first.  
On Linux, make sure you have `git` and a package manager that can install `stow`.

---

## Usage

```text
Usage: python3 scripts/bootstrap.py [options]

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
```

### Verify symlinks
```text
➜  ~ tree -a -P ".*" -L 1 ~
/Users/dielhennr
.
.
├── .gitconfig -> .dotfiles/git/.gitconfig
.
.
├── .zprofile -> .dotfiles/zsh/.zprofile
├── .zsh_aliases -> .dotfiles/zsh/.zsh_aliases
.
.
├── .zshrc -> .dotfiles/zsh/.zshrc
```

### Vim Plug
```bash
# --- Install vim-plug (plugin manager) ---
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

### Neovim + CoC Setup

To get [`coc.nvim`](https://github.com/neoclide/coc.nvim) working properly, you need a recent version of Vim/Neovim, a plugin manager, and Node.js (used by CoC forlanguage servers).

Optionally remove the plugin from init.vim deleting this line.

`Plug 'neoclide/coc.nvim', {'branch': 'release'}`
