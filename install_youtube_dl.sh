#!/usr/bin/env bash

# YouTube Downloader Zsh Function Installer
# This script installs a highly-interactive `youtube` command into your ~/.zshrc

ZSHRC="$HOME/.zshrc"

echo -e "\033[34mInstalling YouTube Downloader function...\033[0m"

# Ensure the .zshrc file exists
if [ ! -f "$ZSHRC" ]; then
    touch "$ZSHRC"
fi

# Remove the old function if it exists to avoid duplicates
sed -i '' '/# YouTube Download (yt-dlp)/,/^}$/d' "$ZSHRC" 2>/dev/null

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

  echo -e "\033[34mFetching available qualities for $1...\033[0m"
  
  local selected_line
  selected_line=$(yt-dlp --cookies-from-browser chrome -F "$1" | grep -v '\[' | fzf --tac --reverse --header="Select format (Arrow keys to navigate, Enter to select)" --prompt="Format> ")

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
  yt-dlp --cookies-from-browser chrome -f "$format_code" -o "$HOME/Downloads/%(title)s.%(ext)s" "$1"
}
EOF

echo -e "\033[32mInstallation complete!\033[0m"
echo -e "\033[33mPlease run 'source ~/.zshrc' to apply the changes, or restart your terminal.\033[0m"
