# macOS (Apple Silicon)
if [ "$(uname)" = "Darwin" ] && [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Linux
if [ "$(uname)" = "Linux" ] && [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi


# Created by `pipx` on 2025-09-18 08:37:30
export PATH="$PATH:/home/ryan/.local/bin"
