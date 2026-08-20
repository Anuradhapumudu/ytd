#!/usr/bin/env bash

# YouTube Downloader Function Installer
# Installs yt-dlp, fzf, and configures the `youtube` command in your shell profile.

set -e

BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

echo -e "${BLUE}Installing YouTube Downloader...${RESET}"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_os() {
  if [[ "$OSTYPE" == darwin* ]]; then
    echo "mac"
  elif [[ "$OSTYPE" == linux* ]]; then
    echo "linux"
  elif [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* || "$OSTYPE" == win32* || "${OS:-}" == "Windows_NT" ]]; then
    echo "windows"
  else
    echo "unknown"
  fi
}

install_package() {
  local package="$1"
  local os
  os="$(detect_os)"
  
  if command_exists "$package"; then
    echo -e "${GREEN}$package is already installed.${RESET}"
    return 0
  fi

  echo -e "${YELLOW}$package not found. Attempting automatic installation...${RESET}"

  if [ "$os" = "mac" ]; then
    if command_exists brew; then
      brew install "$package"
    else
      echo -e "${RED}Homebrew is required on macOS but was not found. Install it from https://brew.sh${RESET}"
      exit 1
    fi
  elif [ "$os" = "linux" ]; then
    if command_exists apt-get; then sudo apt-get update && sudo apt-get install -y "$package"
    elif command_exists dnf; then sudo dnf install -y "$package"
    elif command_exists pacman; then sudo pacman -Sy --noconfirm "$package"
    elif command_exists zypper; then sudo zypper --non-interactive install "$package"
    elif command_exists apk; then sudo apk add "$package"
    else
      echo -e "${RED}No supported Linux package manager found. Please install $package manually.${RESET}"
      exit 1
    fi
  elif [ "$os" = "windows" ]; then
    if command_exists winget; then winget install "$package" --accept-source-agreements --accept-package-agreements
    elif command_exists scoop; then scoop install "$package"
    elif command_exists choco; then choco install "$package" -y
    else
      echo -e "${RED}No supported Windows package manager found (winget/scoop/choco). Please install $package manually.${RESET}"
      exit 1
    fi
  else
    echo -e "${RED}Unsupported OS. Please install $package manually.${RESET}"
    exit 1
  fi
}

install_package "yt-dlp"
install_package "fzf"

# Determine which shell config file to modify
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
  elif [ -f "$HOME/.bash_profile" ]; then
    SHELL_CONFIG="$HOME/.bash_profile"
  else
    SHELL_CONFIG="$HOME/.bashrc"
  fi
else
  # Default fallback if unknown
  SHELL_CONFIG="$HOME/.bashrc"
fi

echo -e "${BLUE}Configuring $SHELL_CONFIG...${RESET}"

if [ ! -f "$SHELL_CONFIG" ]; then
    touch "$SHELL_CONFIG"
fi

# Remove the old function if it exists to avoid duplicates
tmp_config="$(mktemp)"
awk '
  BEGIN { in_block = 0 }
  /^# YouTube Download \(yt-dlp\)/ { in_block = 1; next }
  in_block == 1 && /^}$/ { in_block = 0; next }
  in_block == 0 { print }
' "$SHELL_CONFIG" > "$tmp_config"
mv "$tmp_config" "$SHELL_CONFIG"

# Append the new function
cat << 'EOF' >> "$SHELL_CONFIG"

#########################################################
# YouTube Download (yt-dlp)
#########################################################
function youtube() {
  if [ -z "$1" ]; then
    echo -e "\033[31mUsage: youtube <url>\033[0m"
    return 1
  fi

  if ! command -v yt-dlp >/dev/null 2>&1; then
    echo -e "\033[31myt-dlp is not available in PATH.\033[0m"
    return 1
  fi

  # Auto-detect browser for cookies (bypasses bot protection)
  local cookie_args=()
  if command -v google-chrome >/dev/null 2>&1 || command -v chrome >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1; then
    cookie_args=(--cookies-from-browser chrome)
  fi

  # The Smart TV client bypasses the 1080p limit bot block
  local extractor_args=(--extractor-args "youtube:client=tv")

  echo -e "\033[34mFetching available qualities for $1...\033[0m"

  local selected_line
  selected_line=$(yt-dlp "${cookie_args[@]}" "${extractor_args[@]}" -F "$1" | grep -v '\[' | fzf --tac --reverse --header="Select format (Arrow keys to navigate, Enter to select)" --prompt="Format> ")

  if [ -z "$selected_line" ]; then
    echo -e "\033[33mDownload cancelled.\033[0m"
    return 0
  fi

  # Extract the format code (first word)
  local format_code
  format_code=$(echo "$selected_line" | awk '{print $1}')

  # If it's a video-only format (like 1440p usually is), append best audio
  if echo "$selected_line" | grep -iq "video only"; then
    echo -e "\033[32mVideo-only format selected. Automatically adding best audio...\033[0m"
    format_code="${format_code}+bestaudio"
  fi

  # Default to Downloads directory if it exists, otherwise current directory
  local download_dir="$HOME/Downloads"
  if [ ! -d "$download_dir" ]; then
    download_dir="."
  fi

  echo -e "\033[32mDownloading format $format_code to $download_dir...\033[0m"
  yt-dlp "${cookie_args[@]}" "${extractor_args[@]}" -f "$format_code" -o "$download_dir/%(title)s.%(ext)s" "$1"
}
EOF

echo -e "${GREEN}Installation complete!${RESET}"
echo -e "${YELLOW}Run: source $SHELL_CONFIG (or restart your terminal) to apply changes.${RESET}"
