#!/usr/bin/env python3
import argparse
import os
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path

# -------------------------------
# Defaults (same spirit as bash)
# -------------------------------
DEFAULT_PACKAGES = ["zsh", "nvim", "git", "alacritty", "kitty", "tmux"]
TARGET = Path.home()  # package trees like ".config/alacritty" expect $HOME as -t

# -------------------------------
# Utilities
# -------------------------------
def log(*msg):
    print(*msg, file=sys.stderr)

def have(cmd: str) -> bool:
    return shutil.which(cmd) is not None

def run(cmd, check=False, capture=False, env=None):
    if capture:
        return subprocess.run(cmd, text=True, capture_output=True, check=check, env=env)
    return subprocess.run(cmd, check=check, env=env)

def uname_s() -> str:
    return platform.system()  # "Linux", "Darwin", "Windows"

def is_wsl() -> bool:
    if uname_s() != "Linux":
        return False
    try:
        with open("/proc/version", "r") as f:
            return "microsoft" in f.read().lower()
    except Exception:
        return False

def repo_root_from_this_script() -> Path:
    # This file lives in .../scripts/bootstrap.py → repo root is parent of scripts/
    here = Path(__file__).resolve()
    return here.parent.parent

# -------------------------------
# Install helpers
# -------------------------------
def ensure_stow():
    if have("stow"):
        return
    log("GNU Stow not found; attempting to install...")
    osname = uname_s()
    if osname == "Darwin":
        if not have("brew"):
            log("Homebrew not found; installing...")
            run(['/bin/bash', '-c', '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'])
        run(["brew", "install", "stow"], check=True)
    elif osname == "Linux":
        if have("apt"):
            run(["sudo", "apt", "update"], check=True)
            run(["sudo", "apt", "install", "-y", "stow"], check=True)
        elif have("dnf"):
            run(["sudo", "dnf", "install", "-y", "stow"], check=True)
        elif have("pacman"):
            run(["sudo", "pacman", "-S", "--noconfirm", "stow"], check=True)
        else:
            log("Please install GNU Stow with your package manager and re-run.")
            sys.exit(1)
    else:
        log("Unsupported OS for auto-install. Install stow manually.")
        sys.exit(1)

def ensure_zsh():
    if have("zsh"):
        return
    log("zsh not found; attempting to install...")
    osname = uname_s()
    if osname == "Darwin":
        if not have("brew"):
            log("Homebrew not found; installing...")
            run(['/bin/bash', '-c', '$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)'])
        run(["brew", "install", "zsh"], check=True)
    elif osname == "Linux":
        if have("apt"):
            run(["sudo", "apt", "update"], check=True)
            run(["sudo", "apt", "install", "-y", "zsh"], check=True)
        elif have("dnf"):
            run(["sudo", "dnf", "install", "-y", "zsh"], check=True)
        elif have("pacman"):
            run(["sudo", "pacman", "-S", "--noconfirm", "zsh"], check=True)
        else:
            log("Please install zsh with your package manager and re-run.")
            sys.exit(1)
    else:
        log("Unsupported OS; install zsh manually.")
        sys.exit(1)

def maybe_install_oh_my_zsh(skip_omz: bool):
    if skip_omz:
        return
    omz_dir = Path.home() / ".oh-my-zsh"
    if omz_dir.is_dir():
        log("Oh My Zsh already present; skipping.")
        return
    if not have("zsh"):
        log("zsh not found (should have been installed). Skipping OMZ.")
        return
    if not have("curl"):
        if uname_s() == "Linux":
            if have("apt"):
                run(["sudo", "apt", "install", "-y", "curl"])
            elif have("dnf"):
                run(["sudo", "dnf", "install", "-y", "curl"])
            elif have("pacman"):
                run(["sudo", "pacman", "-S", "--noconfirm", "curl"])
    log("Installing Oh My Zsh (preserving existing ~/.zshrc if any)...")
    env = os.environ.copy()
    env["KEEP_ZSHRC"] = "yes"
    env["RUNZSH"] = "no"
    env["CHSH"] = "no"
    run(["sh", "-c", "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"], env=env)

def ensure_shell_listed_for_chsh():
    zsh_path = shutil.which("zsh")
    if not zsh_path:
        return
    shells = Path("/etc/shells")
    if uname_s() == "Darwin" and shells.exists():
        text = shells.read_text()
        if zsh_path not in text.splitlines():
            log(f"Adding {zsh_path} to /etc/shells so chsh is allowed (macOS).")
            run(["sudo", "bash", "-lc", f"echo {zsh_path} >> /etc/shells"])

def maybe_chsh(do_chsh: bool):
    if not do_chsh:
        return
    if not have("zsh"):
        log("zsh not installed; cannot change default shell.")
        return
    ensure_shell_listed_for_chsh()
    current = os.environ.get("SHELL", "")
    if current.endswith("zsh"):
        log("Default shell already zsh.")
        return
    if is_wsl():
        log("WSL detected: chsh may not affect Windows Terminal profiles.")
    log("Changing default shell to zsh...")
    try:
        run(["chsh", "-s", shutil.which("zsh")], check=True)
        log("Default shell changed to zsh. Log out/in to apply.")
    except subprocess.CalledProcessError:
        log('Could not change shell. Try manually: chsh -s "$(command -v zsh)"')

# -------------------------------
# Backup logic (via stow preview)
# -------------------------------
def backup_if_real_not_symlink(path: Path):
    if path.exists() and not path.is_symlink():
        backup = Path(str(path) + f".pre-stow.{time.strftime('%Y%m%d-%H%M%S')}")
        backup.parent.mkdir(parents=True, exist_ok=True)
        log(f"Backing up {path} -> {backup}")
        shutil.move(str(path), str(backup))

def stow_preview_targets(pkg: str, target: Path):
    """
    Parse `stow -n -v -t <target> <pkg>` output and return target paths to be linked.
    We back up any that exist as non-symlinks to avoid failures.
    """
    proc = run(["stow", "-n", "-v", "-t", str(target), pkg], capture=True)
    out = (proc.stdout or "") + (proc.stderr or "")
    paths = []
    for line in out.splitlines():
        # e.g. 'LINK: .config/alacritty/alacritty.toml -> /home/ryan/.config/alacritty/alacritty.toml'
        # or    'RELINK: ...' (treat same as LINK)
        if line.startswith(("LINK:", "RELINK:")):
            parts = line.split()
            # last token is the absolute target path
            if parts:
                tgt = parts[-1]
                if tgt.startswith(os.sep):
                    paths.append(Path(tgt))
    return out, paths

def backup_conflicts_for_pkg(pkg: str, target: Path):
    # ensure ~/.config exists to allow directory link creation
    (Path.home() / ".config").mkdir(parents=True, exist_ok=True)
    out, paths = stow_preview_targets(pkg, target)
    # (Optional) show preview lines to the user:
    # print(out, end="")
    for p in paths:
        backup_if_real_not_symlink(p)

# -------------------------------
# Stow operations
# -------------------------------
def stow_packages(pkgs, target: Path, dry_run: bool, mode: str):
    flags = []
    if dry_run:
        flags += ["-n", "-v"]
    if mode == "restow":
        flags += ["-R"]
    if mode == "unstow":
        flags = ["-D"] + flags

    # backup (for stow/restow only)
    if mode in ("stow", "restow"):
        for pkg in pkgs:
            backup_conflicts_for_pkg(pkg, target)

    log(("Re-stowing" if mode == "restow" else "Unstowing" if mode == "unstow" else "Stowing")
        + f" packages: {' '.join(pkgs)}")
    cmd = ["stow"] + flags + ["-t", str(target)] + pkgs
    # let stow print its own verbosity in dry-run; otherwise be quiet unless error
    try:
        run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        log("stow failed:", e)
        sys.exit(1)

# -------------------------------
# Conditional stow for Hypr/Waybar
# -------------------------------
def stow_optional_pkg(name: str, require_bin: str):
    if uname_s() != "Linux":
        log(f"{name}: not Linux; skipping.")
        return False
    if not have(require_bin):
        log(f"{name}: {require_bin} not found; skipping.")
        return False
    pkg_dir = (repo_root_from_this_script() / name / ".config" / name)
    if not pkg_dir.exists():
        log(f"{name}: expected '{name}/.config/{name}' in repo; skipping.")
        return False
    # Backup and stow just this package
    backup_conflicts_for_pkg(name, TARGET)
    stow_packages([name], TARGET, dry_run=False, mode="stow")
    return True

# -------------------------------
# CLI
# -------------------------------
def parse_args():
    p = argparse.ArgumentParser(
        description="Dotfiles bootstrap (Python port) — stow, backups, optional installs."
    )
    p.add_argument("--dry-run", action="store_true", help="Show what would happen without making changes")
    p.add_argument("--no-ohmyzsh", action="store_true", help="Skip installing Oh My Zsh")
    p.add_argument("--chsh", action="store_true", help="Change default shell to zsh if not already")
    p.add_argument("--packages", type=str, help=f'Space-separated list (default: {" ".join(DEFAULT_PACKAGES)})')
    p.add_argument("--unstow", action="store_true", help="Remove symlinks for the selected packages")
    p.add_argument("--restow", action="store_true", help="Re-link (stow -R) selected packages")
    return p.parse_args()

# -------------------------------
# Main
# -------------------------------
def main():
    # Work from repo root (like `cd "$(dirname "$0")"` in bash)
    repo = repo_root_from_this_script()
    os.chdir(repo)

    args = parse_args()
    mode = "stow"
    if args.unstow:
        mode = "unstow"
    elif args.restow:
        mode = "restow"

    packages = DEFAULT_PACKAGES if not args.packages else args.packages.split()
    # Ensure required tools and shell
    ensure_stow()
    ensure_zsh()
    maybe_install_oh_my_zsh(args.no_ohmyzsh)
    maybe_chsh(args.chsh)

    # Backups + stow/unstow selected packages
    stow_packages(packages, TARGET, dry_run=args.dry_run, mode=mode)

    # Optional extras (Linux-only)
    # Try Hyprland and Waybar like the bash script did:
    if "hypr" in packages:
        stow_optional_pkg("hypr", "hyprctl")
    if "waybar" in packages:
        stow_optional_pkg("waybar", "waybar")

    if not args.dry_run and mode != "unstow":
        log("\nVerify symlinks (examples):")
        for f in [
            "~/.zshrc",
            "~/.gitconfig",
            "~/.tmux.conf",
            "~/.config/kitty"
            "~/.config/nvim",
            "~/.config/alacritty",
            "~/.config/hypr",
            "~/.config/waybar",
        ]:
            p = Path(os.path.expanduser(f))
            if p.exists():
                try:
                    log(run(["ls", "-l", str(p)], capture=True).stdout.strip())
                except Exception:
                    log(str(p))
        log("\nDone.")
        if args.chsh:
            log("Tip: run 'zsh' to test now (default will apply next login).")

if __name__ == "__main__":
    main()
