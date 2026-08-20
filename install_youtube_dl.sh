#!/usr/bin/env bash

# YouTube Downloader Zsh Function Installer
# This script installs a highly-interactive `youtube` command into your ~/.zshrc

set -e

ZSHRC="$HOME/.zshrc"

BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

echo -e "${BLUE}Installing YouTube Downloader function...${RESET}"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_os() {
  if [[ "$OSTYPE" == darwin* ]]; then
    echo "mac"
    return
  fi

  if [[ "$OSTYPE" == linux* ]]; then
    echo "linux"
    return
  fi

  if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || "$OSTYPE" == win32* || "${OS:-}" == "Windows_NT" ]]; then
    echo "windows"
    return
  fi

  echo "unknown"
}

install_with_linux_pkg_manager() {
  local package="$1"

  if command_exists apt-get; then
    sudo apt-get update && sudo apt-get install -y "$package"
    return
  fi
  if command_exists dnf; then
    sudo dnf install -y "$package"
    return
  fi
  if command_exists yum; then
    sudo yum install -y "$package"
    return
  fi
  if command_exists pacman; then
    sudo pacman -Sy --noconfirm "$package"
    return
  fi
  if command_exists zypper; then
    sudo zypper --non-interactive install "$package"
    return
  fi
  if command_exists apk; then
    sudo apk add "$package"
    return
  fi
  if command_exists snap; then
    sudo snap install "$package"
    return
  fi
  if command_exists brew; then
    brew install "$package"
    return
  fi

  return 1
}

install_with_windows_pkg_manager() {
  if command_exists winget; then
    winget install --id yt-dlp.yt-dlp --accept-source-agreements --accept-package-agreements
    return
  fi
  if command_exists scoop; then
    scoop install yt-dlp
    return
  fi
  if command_exists choco; then
    choco install yt-dlp -y
    return
  fi

  return 1
}

ensure_yt_dlp_installed() {
  if command_exists yt-dlp; then
    echo -e "${GREEN}yt-dlp is already installed.${RESET}"
    return
  fi

  echo -e "${YELLOW}yt-dlp not found. Attempting automatic installation...${RESET}"

  local os
  os="$(detect_os)"

  case "$os" in
    mac)
      if command_exists brew; then
        brew install yt-dlp
      else
        echo -e "${RED}Homebrew is required on macOS but was not found.${RESET}"
        echo -e "${YELLOW}Install Homebrew first: https://brew.sh${RESET}"
        exit 1
      fi
      ;;
    linux)
      if ! install_with_linux_pkg_manager yt-dlp; then
        echo -e "${RED}No supported Linux package manager found to install yt-dlp automatically.${RESET}"
        exit 1
      fi
      ;;
    windows)
      if ! install_with_windows_pkg_manager; then
        echo -e "${RED}No supported Windows package manager found (winget/scoop/choco).${RESET}"
        exit 1
      fi
      ;;
    *)
      echo -e "${RED}Unsupported OS. Please install yt-dlp manually.${RESET}"
      exit 1
      ;;
  esac

  if command_exists yt-dlp; then
    echo -e "${GREEN}yt-dlp installed successfully.${RESET}"
  else
    echo -e "${RED}yt-dlp installation appears to have failed.${RESET}"
    exit 1
  fi
}

ensure_yt_dlp_installed

# Ensure the .zshrc file exists
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

# Remove the old function if it exists to avoid duplicates
tmp_zshrc="$(mktemp)"
awk '
  BEGIN { in_block = 0 }
  /^# YouTube Download \(yt-dlp\)/ { in_block = 1; next }
  in_block == 1 && /^}$/ { in_block = 0; next }
  in_block == 0 { print }
' "$ZSHRC" > "$tmp_zshrc"
mv "$tmp_zshrc" "$ZSHRC"

# Append the new function
cat << 'EOF' >> "$ZSHRC"

#########################################################
# YouTube Download (yt-dlp)
#########################################################
function youtube() {
  if [ -z "$1" ]; then
    echo -e "\033[31mUsage: youtube <url>\033[0m"
    return 1
  fi

  if ! command -v yt-dlp >/dev/null 2>&1; then
    echo -e "\033[31myt-dlp is not available in PATH. Re-run install_youtube_dl.sh.\033[0m"
    return 1
  fi

  local cookie_args=()
  if command -v google-chrome >/dev/null 2>&1 || command -v chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1; then
    cookie_args=(--cookies-from-browser chrome)
  fi

  echo -e "\033[34mFetching available qualities for $1...\033[0m"

  if ! command -v fzf >/dev/null 2>&1; then
    echo -e "\033[33mfzf not found. Downloading best quality instead.\033[0m"
    yt-dlp "${cookie_args[@]}" -f "bestvideo+bestaudio/best" -o "$HOME/Downloads/%(title)s.%(ext)s" "$1"
    return $?
  fi

  local selected_line
  selected_line=$(yt-dlp "${cookie_args[@]}" -F "$1" | grep -v '\[' | fzf --tac --reverse --header="Select format (Arrow keys to navigate, Enter to select)" --prompt="Format> ")

  if [ -z "$selected_line" ]; then
    echo -e "\033[33mDownload cancelled.\033[0m"
    return 0
  fi

  # Extract the format code (first word)
  local format_code
  format_code=$(echo "$selected_line" | awk '{print $1}')

  # If it's a video-only format (like 1440p usually is), append audio
  if echo "$selected_line" | grep -iq "video only"; then
    echo -e "\033[32mVideo-only format selected. Automatically adding best audio...\033[0m"
    format_code="${format_code}+bestaudio"
  fi

  echo -e "\033[32mDownloading format $format_code to ~/Downloads...\033[0m"
  yt-dlp "${cookie_args[@]}" -f "$format_code" -o "$HOME/Downloads/%(title)s.%(ext)s" "$1"
}
EOF

echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${YELLOW}Run: source ~/.zshrc (or restart terminal) to apply changes.${RESET}"
