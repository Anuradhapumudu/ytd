#!/usr/bin/env bash

# ─────────────────────────────────────────────────────────────────────────────
# YouTube Downloader — Interactive CLI Installer
# Installs yt-dlp, ffmpeg, fzf, and injects the `youtube` shell function
# into your ~/.zshrc or ~/.bashrc.
#
# Supports: macOS (Homebrew), Linux (apt/dnf/yum/pacman/zypper/apk/snap/brew),
#           Windows (winget/scoop/choco via Git Bash/MSYS2/WSL).
# ─────────────────────────────────────────────────────────────────────────────

set -e

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
BLUE='\033[34m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
RESET='\033[0m'

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}  ╔═══════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}  ║            ${MAGENTA}▶  YouTube Downloader  ◀${CYAN}              ║${RESET}"
echo -e "${CYAN}${BOLD}  ║         ${DIM}${CYAN}Interactive CLI  •  v2.0${RESET}${CYAN}${BOLD}                ║${RESET}"
echo -e "${CYAN}${BOLD}  ╚═══════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Helpers ───────────────────────────────────────────────────────────────────
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

info()    { echo -e "  ${BLUE}ℹ${RESET}  $1"; }
success() { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
fail()    { echo -e "  ${RED}✖${RESET}  $1"; }

# ── Detect OS ─────────────────────────────────────────────────────────────────
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

# ── Detect Shell RC File ─────────────────────────────────────────────────────
detect_rc_file() {
  local current_shell
  current_shell="$(basename "${SHELL:-/bin/bash}")"

  if [[ "$current_shell" == "zsh" ]]; then
    echo "$HOME/.zshrc"
  elif [[ "$current_shell" == "bash" ]]; then
    echo "$HOME/.bashrc"
  else
    # Fallback: check if .zshrc exists, otherwise .bashrc
    if [[ -f "$HOME/.zshrc" ]]; then
      echo "$HOME/.zshrc"
    else
      echo "$HOME/.bashrc"
    fi
  fi
}

# ── Package Installers ───────────────────────────────────────────────────────
install_mac() {
  local package="$1"
  if command_exists brew; then
    brew install "$package"
  else
    fail "Homebrew is required on macOS but was not found."
    echo -e "     Install it first: ${CYAN}https://brew.sh${RESET}"
    exit 1
  fi
}

install_linux() {
  local package="$1"

  if command_exists apt-get; then
    sudo apt-get update -qq && sudo apt-get install -y "$package"
    return 0
  fi
  if command_exists dnf; then
    sudo dnf install -y "$package"
    return 0
  fi
  if command_exists yum; then
    sudo yum install -y "$package"
    return 0
  fi
  if command_exists pacman; then
    sudo pacman -Sy --noconfirm "$package"
    return 0
  fi
  if command_exists zypper; then
    sudo zypper --non-interactive install "$package"
    return 0
  fi
  if command_exists apk; then
    sudo apk add "$package"
    return 0
  fi
  if command_exists snap; then
    sudo snap install "$package"
    return 0
  fi
  if command_exists brew; then
    brew install "$package"
    return 0
  fi

  return 1
}

install_windows() {
  local package="$1"

  if command_exists winget; then
    winget install --id "$package" --accept-source-agreements --accept-package-agreements 2>/dev/null
    return 0
  fi
  if command_exists scoop; then
    scoop install "$package"
    return 0
  fi
  if command_exists choco; then
    choco install "$package" -y
    return 0
  fi

  return 1
}

# ── winget IDs differ from package names ──────────────────────────────────────
winget_id_for() {
  case "$1" in
    yt-dlp)  echo "yt-dlp.yt-dlp" ;;
    ffmpeg)  echo "Gyan.FFmpeg" ;;
    fzf)     echo "junegunn.fzf" ;;
    *)       echo "$1" ;;
  esac
}

# ── Ensure a dependency is installed ──────────────────────────────────────────
ensure_installed() {
  local name="$1"

  if command_exists "$name"; then
    success "${BOLD}$name${RESET} is already installed."
    return
  fi

  warn "${BOLD}$name${RESET} not found — installing..."

  local os
  os="$(detect_os)"

  case "$os" in
    mac)
      install_mac "$name"
      ;;
    linux)
      if ! install_linux "$name"; then
        fail "Could not find a package manager to install ${BOLD}$name${RESET}."
        exit 1
      fi
      ;;
    windows)
      local winget_name
      winget_name="$(winget_id_for "$name")"
      if ! install_windows "$winget_name"; then
        fail "No supported Windows package manager found (winget/scoop/choco)."
        exit 1
      fi
      ;;
    *)
      fail "Unsupported OS. Please install ${BOLD}$name${RESET} manually."
      exit 1
      ;;
  esac

  if command_exists "$name"; then
    success "${BOLD}$name${RESET} installed successfully."
  else
    fail "${BOLD}$name${RESET} installation appears to have failed."
    exit 1
  fi
}

# ── Install Dependencies ─────────────────────────────────────────────────────
echo -e "${BOLD}  Installing dependencies...${RESET}"
echo ""

ensure_installed yt-dlp
ensure_installed ffmpeg
ensure_installed fzf

echo ""

# ── Detect RC File ────────────────────────────────────────────────────────────
RC_FILE="$(detect_rc_file)"

if [[ ! -f "$RC_FILE" ]]; then
  touch "$RC_FILE"
fi

info "Shell config: ${BOLD}$RC_FILE${RESET}"

# ── Remove Old Function (if exists) ──────────────────────────────────────────
tmp_rc="$(mktemp)"
awk '
  BEGIN { in_block = 0 }
  /^# YouTube Download \(yt-dlp\)/ || /^#+ YouTube Download/ { in_block = 1; next }
  in_block == 1 && /^}$/ { in_block = 0; next }
  in_block == 0 { print }
' "$RC_FILE" > "$tmp_rc"
mv "$tmp_rc" "$RC_FILE"

# ── Inject the youtube() Function ─────────────────────────────────────────────
cat << 'FUNC_EOF' >> "$RC_FILE"

#########################################################
# YouTube Download (yt-dlp) — v2.3
# Cookie-free by default. Auto-detects playlists.
# Visual progress bar. Auto-update checking.
#########################################################
function youtube() {
  # ── Version ──
  local YTD_VERSION="2.3"
  local YTD_REPO="Anuradhapumudu/ytd"
  local YTD_RAW="https://raw.githubusercontent.com/${YTD_REPO}/main/install-ytd.sh"

  # ── Colors ──
  local _B='\033[1m' _D='\033[2m' _R='\033[0m'
  local _BLUE='\033[34m' _CYAN='\033[36m' _GREEN='\033[32m'
  local _YELLOW='\033[33m' _RED='\033[31m' _MAGENTA='\033[35m'
  local _WHITE='\033[97m' _GRAY='\033[90m'

  # ── Progress Bar Renderer ──
  # Single-line. No \n ever. Pure string ops — no grep/sed subprocesses.
  # All locals declared at top to prevent zsh variable-leak in pipe subshells.
  _ytd_progress() {
    local _bw=35 _last=-1
    local _ln _tmp _pct _f _e _bar _j _sz _sp _et
    while IFS= read -r _ln; do
      case "$_ln" in
        "[download]"*"%"*)
          _tmp="${_ln#*\] }"
          _tmp="${_tmp# }"
          _tmp="${_tmp%%\%*}"
          _tmp="${_tmp##* }"
          _pct="${_tmp%%.*}"
          _pct="${_pct// /}"
          if [[ "$_pct" =~ ^[0-9]+$ ]] && [[ "$_pct" != "$_last" ]]; then
            _last=$_pct
            _f=$((_pct * _bw / 100))
            _e=$((_bw - _f))
            _bar=""
            _j=0; while [[ $_j -lt $_f ]]; do _bar="${_bar}█"; _j=$((_j + 1)); done
            _j=0; while [[ $_j -lt $_e ]]; do _bar="${_bar}░"; _j=$((_j + 1)); done
            if [[ $_pct -ge 100 ]]; then
              printf '\r\033[K  \033[32m%s\033[0m \033[1m100%%\033[0m  \033[90mComplete\033[0m' "$_bar"
            else
              _sz="..."; _sp="..."; _et="..."
              case "$_ln" in *" of "*) _tmp="${_ln#* of }"; _tmp="${_tmp#\~ }"; _tmp="${_tmp# }"; _sz="${_tmp%% *}";; esac
              case "$_ln" in *" at "*) _tmp="${_ln#* at }"; _tmp="${_tmp# }"; _sp="${_tmp%% *}";; esac
              case "$_ln" in *"ETA "*) _tmp="${_ln#*ETA }"; _et="${_tmp%% *}";; esac
              printf '\r\033[K  \033[32m%s\033[0m \033[1m%3d%%\033[0m  \033[90m%s  %s  ETA %s\033[0m' \
                "$_bar" "$_pct" "$_sz" "$_sp" "$_et"
            fi
          fi
          ;;
        "[Merger]"*)
          printf '\r\033[K  \033[36m⟳\033[0m  Merging video + audio...'
          ;;
        "[ExtractAudio]"*)
          printf '\r\033[K  \033[35m♫\033[0m  Extracting audio...'
          ;;
        "[download] Downloading"*)
          _tmp="${_ln#\[download\] }"
          printf '\r\033[K  \033[36m▶\033[0m  %s' "$_tmp"
          _last=-1
          ;;
        "[download] Destination:"*)
          _last=-1
          ;;
        "[download]"*"already been downloaded"*)
          printf '\r\033[K  \033[90m⏭  Skipping (already downloaded)\033[0m'
          ;;
      esac
    done
    printf '\r\033[K'
  }

  # ── Argument Parsing ──
  local use_cookies=false
  local mode="interactive"   # interactive | best | audio-mp3 | audio-m4a
  local output_format="mp4"
  local download_dir="$HOME/Downloads"
  local notify=false
  local force_playlist=false
  local url=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        echo ""
        echo -e "${_CYAN}${_B}  ▶  YouTube Downloader  v${YTD_VERSION}${_R}"
        echo ""
        echo -e "  ${_B}USAGE${_R}"
        echo -e "    ${_GREEN}youtube${_R} ${_GRAY}[options]${_R} ${_WHITE}<url>${_R}"
        echo ""
        echo -e "  ${_B}OPTIONS${_R}"
        echo -e "    ${_GREEN}-b${_R}, ${_GREEN}--best${_R}        Download best quality (skip picker)"
        echo -e "    ${_GREEN}-a${_R}, ${_GREEN}--audio${_R}       Download audio only (MP3, 320kbps)"
        echo -e "    ${_GREEN}-m${_R}, ${_GREEN}--m4a${_R}         Download audio only (M4A/AAC)"
        echo -e "    ${_GREEN}-p${_R}, ${_GREEN}--playlist${_R}    Force playlist mode (skip confirmation)"
        echo -e "    ${_GREEN}-c${_R}, ${_GREEN}--cookies${_R}     Use browser cookies (private/age-restricted)"
        echo -e "    ${_GREEN}-o${_R}, ${_GREEN}--output${_R} DIR  Set download directory (default: ~/Downloads)"
        echo -e "    ${_GREEN}--mkv${_R}            Output as MKV instead of MP4"
        echo -e "    ${_GREEN}-n${_R}, ${_GREEN}--notify${_R}      Send desktop notification on completion (macOS)"
        echo -e "    ${_GREEN}--update${_R}         Update to the latest version from GitHub"
        echo -e "    ${_GREEN}--version${_R}        Show current version"
        echo -e "    ${_GREEN}-h${_R}, ${_GREEN}--help${_R}        Show this help"
        echo ""
        echo -e "  ${_B}EXAMPLES${_R}"
        echo -e "    ${_GRAY}# Interactive format picker (single video)${_R}"
        echo -e "    youtube https://youtu.be/dQw4w9WgXcQ"
        echo ""
        echo -e "    ${_GRAY}# Best quality, no picker${_R}"
        echo -e "    youtube -b https://youtu.be/dQw4w9WgXcQ"
        echo ""
        echo -e "    ${_GRAY}# Audio only (MP3)${_R}"
        echo -e "    youtube -a https://youtu.be/dQw4w9WgXcQ"
        echo ""
        echo -e "    ${_GRAY}# Download entire playlist (auto-detected)${_R}"
        echo -e "    youtube -b https://youtube.com/playlist?list=PLxxxxxx"
        echo ""
        echo -e "    ${_GRAY}# Playlist audio-only, skip confirmation${_R}"
        echo -e "    youtube -p -a https://youtube.com/playlist?list=PLxxxxxx"
        echo ""
        echo -e "    ${_GRAY}# Private video with cookies${_R}"
        echo -e "    youtube -c https://youtu.be/PRIVATE_ID"
        echo ""
        return 0
        ;;
      -b|--best)
        mode="best"
        shift
        ;;
      -a|--audio)
        mode="audio-mp3"
        shift
        ;;
      -m|--m4a)
        mode="audio-m4a"
        shift
        ;;
      -p|--playlist)
        force_playlist=true
        shift
        ;;
      -c|--cookies)
        use_cookies=true
        shift
        ;;
      -o|--output)
        if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
          download_dir="$2"
          shift 2
        else
          echo -e "  ${_RED}✖${_R}  ${_RED}--output requires a directory path${_R}"
          return 1
        fi
        ;;
      --mkv)
        output_format="mkv"
        shift
        ;;
      -n|--notify)
        notify=true
        shift
        ;;
      --update)
        echo ""
        echo -e "  ${_CYAN}⟳${_R}  Updating YouTube Downloader..."
        echo ""
        if bash <(curl -sL "$YTD_RAW"); then
          rm -f "$HOME/.ytd_update_notice"
          echo ""
          echo -e "  ${_GREEN}✔${_R}  Update complete. Run ${_B}source $([ -f ~/.zshrc ] && echo ~/.zshrc || echo ~/.bashrc)${_R} to apply."
        else
          echo -e "  ${_RED}✖${_R}  Update failed. Check your internet connection."
        fi
        return 0
        ;;
      --version)
        echo -e "  ${_CYAN}▶${_R}  YouTube Downloader ${_B}v${YTD_VERSION}${_R}"
        return 0
        ;;
      -*)
        echo -e "  ${_RED}✖${_R}  Unknown option: ${_B}$1${_R}"
        echo -e "  ${_GRAY}Run ${_GREEN}youtube --help${_GRAY} for usage.${_R}"
        return 1
        ;;
      *)
        url="$1"
        shift
        ;;
    esac
  done

  # ── Auto-Update Check (background, once per 24h) ──
  (
    local _check_file="$HOME/.ytd_last_check"
    local _notice_file="$HOME/.ytd_update_notice"
    local _now; _now=$(date +%s)
    local _last=0
    [[ -f "$_check_file" ]] && _last=$(cat "$_check_file" 2>/dev/null)
    if (( _now - _last > 86400 )); then
      echo "$_now" > "$_check_file"
      local _remote
      _remote=$(curl -sL --max-time 5 "$YTD_RAW" 2>/dev/null | grep -m1 'YTD_VERSION=' | head -1 | cut -d'"' -f2)
      if [[ -n "$_remote" && "$_remote" != "$YTD_VERSION" ]]; then
        echo "$_remote" > "$_notice_file"
      else
        rm -f "$_notice_file"
      fi
    fi
  ) &>/dev/null &
  disown 2>/dev/null

  # ── Show Update Notice (if available from previous check) ──
  if [[ -f "$HOME/.ytd_update_notice" ]]; then
    local _new_ver
    _new_ver=$(cat "$HOME/.ytd_update_notice" 2>/dev/null)
    if [[ -n "$_new_ver" && "$_new_ver" != "$YTD_VERSION" ]]; then
      echo -e "  ${_YELLOW}⬆${_R}  Update available: ${_B}v${_new_ver}${_R} ${_GRAY}(current: v${YTD_VERSION})${_R}. Run ${_GREEN}youtube --update${_R} to upgrade."
    else
      rm -f "$HOME/.ytd_update_notice"
    fi
  fi

  # ── Validate URL ──
  if [[ -z "$url" ]]; then
    echo ""
    echo -e "  ${_CYAN}${_B}▶  YouTube Downloader  v${YTD_VERSION}${_R}"
    echo ""
    echo -e "  ${_RED}✖${_R}  No URL provided."
    echo -e "  ${_GRAY}Usage: ${_GREEN}youtube${_GRAY} [options] <url>${_R}"
    echo -e "  ${_GRAY}Run ${_GREEN}youtube --help${_GRAY} for full usage.${_R}"
    echo ""
    return 1
  fi

  # ── Check Dependencies ──
  local missing=()
  command -v yt-dlp  >/dev/null 2>&1 || missing+=(yt-dlp)
  command -v ffmpeg  >/dev/null 2>&1 || missing+=(ffmpeg)
  if [[ "$mode" == "interactive" ]]; then
    command -v fzf >/dev/null 2>&1 || missing+=(fzf)
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "  ${_RED}✖${_R}  Missing dependencies: ${_B}${missing[*]}${_R}"
    echo -e "  ${_GRAY}Re-run the installer or install manually.${_R}"
    return 1
  fi

  # ── Cookie Handling (opt-in only — no Keychain prompt by default) ──
  local cookie_args=()

  if [[ "$use_cookies" == true ]]; then
    local browser_found=false

    # macOS
    if [[ -d "/Applications/Google Chrome.app" ]]; then
      cookie_args=(--cookies-from-browser chrome)
      browser_found=true
      if pgrep -x "Google Chrome" >/dev/null 2>&1; then
        echo -e "  ${_YELLOW}⚠${_R}  Chrome is running — quit it (${_B}Cmd+Q${_R}) if cookie extraction fails."
      fi
    elif [[ -d "/Applications/Brave Browser.app" ]]; then
      cookie_args=(--cookies-from-browser brave)
      browser_found=true
      if pgrep -x "Brave Browser" >/dev/null 2>&1; then
        echo -e "  ${_YELLOW}⚠${_R}  Brave is running — quit it (${_B}Cmd+Q${_R}) if cookie extraction fails."
      fi
    fi

    # Linux / Windows — try common Chromium paths
    if [[ "$browser_found" == false ]]; then
      if command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1; then
        cookie_args=(--cookies-from-browser chrome)
        browser_found=true
      elif command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
        cookie_args=(--cookies-from-browser chromium)
        browser_found=true
      elif command -v brave-browser >/dev/null 2>&1; then
        cookie_args=(--cookies-from-browser brave)
        browser_found=true
      elif command -v firefox >/dev/null 2>&1; then
        cookie_args=(--cookies-from-browser firefox)
        browser_found=true
      fi
    fi

    if [[ "$browser_found" == true ]]; then
      echo -e "  ${_BLUE}ℹ${_R}  Using browser cookies. macOS may prompt for Keychain access."
    else
      echo -e "  ${_YELLOW}⚠${_R}  No supported browser found — continuing without cookies."
    fi
  fi

  # ── Ensure download directory exists ──
  mkdir -p "$download_dir"

  # ═══════════════════════════════════════════════════════════════════════════
  # ── AUTO-DETECT: Playlist or Single Video? ──
  # ═══════════════════════════════════════════════════════════════════════════
  local is_playlist=false

  if [[ "$url" == *"playlist?list="* ]] || [[ "$url" == *"/sets/"* ]]; then
    is_playlist=true
  elif [[ "$url" == *"&list="* ]] || [[ "$url" == *"?list="* ]]; then
    is_playlist=true
  fi

  if [[ "$force_playlist" == true ]]; then
    is_playlist=true
  fi

  # ═══════════════════════════════════════════════════════════════════════════
  # ── PLAYLIST MODE ──
  # ═══════════════════════════════════════════════════════════════════════════
  if [[ "$is_playlist" == true ]]; then

    echo ""
    echo -ne "  ${_CYAN}⟳${_R}  Scanning playlist..."

    local playlist_info playlist_title playlist_count
    playlist_info=$(yt-dlp "${cookie_args[@]}" --flat-playlist --dump-json "$url" 2>/dev/null)

    if [[ -z "$playlist_info" ]]; then
      echo -ne "\r\033[K"
      echo -e "  ${_RED}✖${_R}  ${_RED}Could not fetch playlist info.${_R}"
      if [[ "$use_cookies" == false ]]; then
        echo -e "  ${_YELLOW}💡${_R}  ${_YELLOW}If this is a private playlist, retry with:${_R}"
        echo -e "     ${_GREEN}youtube -c ${url}${_R}"
      fi
      return 1
    fi

    playlist_count=$(echo "$playlist_info" | wc -l | tr -d ' ')

    playlist_title=$(echo "$playlist_info" | head -1 | grep -o '"playlist_title":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -z "$playlist_title" ]]; then
      playlist_title="Playlist"
    fi

    echo -ne "\r\033[K"

    # ── Playlist Info Card ──
    echo -e "  ${_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
    echo -e "  ${_B}${_WHITE}  📋  ${playlist_title}${_R}"
    echo -e "  ${_GRAY}      ${playlist_count} videos${_R}"
    echo -e "  ${_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
    echo ""

    # ── Confirmation (unless -p was passed) ──
    if [[ "$force_playlist" == false ]]; then
      local confirm_msg
      case "$mode" in
        best)       confirm_msg="best quality" ;;
        audio-mp3)  confirm_msg="audio (MP3)" ;;
        audio-m4a)  confirm_msg="audio (M4A)" ;;
        *)          confirm_msg="best quality" ;;
      esac

      echo -ne "  ${_YELLOW}?${_R}  Download all ${_B}${playlist_count}${_R} videos as ${_B}${confirm_msg}${_R}? [Y/n] "
      local answer
      read -r answer
      case "$answer" in
        [nN]|[nN][oO])
          echo -e "  ${_YELLOW}✖${_R}  ${_YELLOW}Download cancelled.${_R}"
          return 0
          ;;
      esac

      if [[ "$mode" == "interactive" ]]; then
        mode="best"
      fi
    else
      if [[ "$mode" == "interactive" ]]; then
        mode="best"
      fi
    fi

    # ── Create playlist subdirectory ──
    local playlist_dir="$download_dir/${playlist_title}"
    mkdir -p "$playlist_dir"

    echo ""
    local dl_label
    case "$mode" in
      best)       dl_label="best quality" ;;
      audio-mp3)  dl_label="audio (MP3 320kbps)" ;;
      audio-m4a)  dl_label="audio (M4A/AAC)" ;;
    esac

    echo -e "  ${_GREEN}▶${_R}  Downloading ${_B}${playlist_count} videos${_R} — ${_B}${dl_label}${_R}"
    echo -e "  ${_GRAY}   📁  ${playlist_dir}${_R}"
    echo ""

    local start_time=$SECONDS
    local dl_status=0

    case "$mode" in
      best)
        (set -o pipefail; yt-dlp \
          "${cookie_args[@]}" \
          --yes-playlist \
          -f "bestvideo+bestaudio/best" \
          --merge-output-format "$output_format" \
          --newline \
          -o "$playlist_dir/%(playlist_index)03d - %(title).180s.%(ext)s" \
          "$url" 2>&1 | _ytd_progress) || dl_status=$?
        ;;
      audio-mp3)
        (set -o pipefail; yt-dlp \
          "${cookie_args[@]}" \
          --yes-playlist \
          -x --audio-format mp3 --audio-quality 0 \
          --newline \
          -o "$playlist_dir/%(playlist_index)03d - %(title).180s.%(ext)s" \
          "$url" 2>&1 | _ytd_progress) || dl_status=$?
        ;;
      audio-m4a)
        (set -o pipefail; yt-dlp \
          "${cookie_args[@]}" \
          --yes-playlist \
          -x --audio-format m4a --audio-quality 0 \
          --newline \
          -o "$playlist_dir/%(playlist_index)03d - %(title).180s.%(ext)s" \
          "$url" 2>&1 | _ytd_progress) || dl_status=$?
        ;;
    esac

    local elapsed=$(( SECONDS - start_time ))

    local elapsed_str
    if [[ $elapsed -ge 3600 ]]; then
      elapsed_str="$((elapsed / 3600))h $((elapsed % 3600 / 60))m $((elapsed % 60))s"
    elif [[ $elapsed -ge 60 ]]; then
      elapsed_str="$((elapsed / 60))m $((elapsed % 60))s"
    else
      elapsed_str="${elapsed}s"
    fi

    echo ""
    if [[ $dl_status -eq 0 ]]; then
      local file_count
      file_count=$(find "$playlist_dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')

      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
      echo -e "  ${_GREEN}✔${_R}  ${_B}Playlist download complete${_R}  ${_GRAY}(${elapsed_str})${_R}"
      echo -e "  ${_GRAY}     ${file_count} files downloaded${_R}"
      echo -e "  ${_GRAY}   📁  ${playlist_dir}${_R}"
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"

      if [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"${playlist_title} — ${file_count} files\" with title \"Playlist Download Complete\" sound name \"Glass\""
      fi
    else
      echo -e "  ${_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
      echo -e "  ${_YELLOW}⚠${_R}  ${_B}Playlist download finished with errors${_R}  ${_GRAY}(${elapsed_str})${_R}"
      echo -e "  ${_GRAY}     Some videos may have been skipped.${_R}"
      echo -e "  ${_GRAY}   📁  ${playlist_dir}${_R}"
      echo -e "  ${_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
      return 1
    fi

    return 0
  fi

  # ═══════════════════════════════════════════════════════════════════════════
  # ── SINGLE VIDEO MODE ──
  # ═══════════════════════════════════════════════════════════════════════════

  # ── Fetch Video Info (title, channel, duration) ──
  # Uses --print for reliable extraction instead of JSON parsing
  echo ""
  echo -ne "  ${_CYAN}⟳${_R}  Fetching video info..."

  local video_title="Unknown Title"
  local video_channel=""
  local video_duration=""
  local video_info_raw

  video_info_raw=$(yt-dlp "${cookie_args[@]}" --no-playlist \
    --print "%(title)s" \
    --print "%(channel)s" \
    --print "%(duration_string)s" \
    "$url" 2>/dev/null || true)

  if [[ -n "$video_info_raw" ]]; then
    video_title=$(echo "$video_info_raw" | sed -n '1p')
    video_channel=$(echo "$video_info_raw" | sed -n '2p')
    video_duration=$(echo "$video_info_raw" | sed -n '3p')
  fi

  # Fallbacks for empty fields
  [[ -z "$video_title" ]] && video_title="Unknown Title"
  [[ -z "$video_channel" ]] && video_channel="Unknown"
  [[ -z "$video_duration" ]] && video_duration="?"

  echo -ne "\r\033[K"

  # ── Video Info Card ──
  echo -e "  ${_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
  echo -e "  ${_B}${_WHITE}  ${video_title}${_R}"
  echo -e "  ${_GRAY}  ${video_channel}  •  ${video_duration}${_R}"
  echo -e "  ${_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
  echo ""

  # ── Mode: Best Quality ──
  if [[ "$mode" == "best" ]]; then
    echo -e "  ${_GREEN}▶${_R}  Downloading ${_B}best quality${_R} → ${_GRAY}$download_dir${_R}"
    echo ""

    local start_time=$SECONDS
    local dl_status=0

    (set -o pipefail; yt-dlp \
      "${cookie_args[@]}" \
      --no-playlist \
      -f "bestvideo+bestaudio/best" \
      --merge-output-format "$output_format" \
      --newline \
      -o "$download_dir/%(title).200s.%(ext)s" \
      "$url" 2>&1 | _ytd_progress) || dl_status=$?

    if [[ $dl_status -eq 0 ]]; then
      local elapsed=$(( SECONDS - start_time ))
      echo ""
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
      echo -e "  ${_GREEN}✔${_R}  ${_B}Download complete${_R}  ${_GRAY}(${elapsed}s)${_R}"
      echo -e "  ${_GRAY}   📁  $download_dir${_R}"
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"

      if [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"${video_title}\" with title \"Download Complete\" sound name \"Glass\""
      fi
    else
      echo ""
      echo -e "  ${_RED}✖${_R}  ${_RED}Download failed.${_R}"
      return 1
    fi
    return 0
  fi

  # ── Mode: Audio MP3 ──
  if [[ "$mode" == "audio-mp3" ]]; then
    echo -e "  ${_MAGENTA}♫${_R}  Downloading ${_B}audio (MP3 320kbps)${_R} → ${_GRAY}$download_dir${_R}"
    echo ""

    local start_time=$SECONDS
    local dl_status=0

    (set -o pipefail; yt-dlp \
      "${cookie_args[@]}" \
      --no-playlist \
      -x --audio-format mp3 --audio-quality 0 \
      --newline \
      -o "$download_dir/%(title).200s.%(ext)s" \
      "$url" 2>&1 | _ytd_progress) || dl_status=$?

    if [[ $dl_status -eq 0 ]]; then
      local elapsed=$(( SECONDS - start_time ))
      echo ""
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
      echo -e "  ${_GREEN}✔${_R}  ${_B}Audio download complete${_R}  ${_GRAY}(${elapsed}s)${_R}"
      echo -e "  ${_GRAY}   📁  $download_dir${_R}"
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"

      if [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"${video_title}\" with title \"Audio Download Complete\" sound name \"Glass\""
      fi
    else
      echo ""
      echo -e "  ${_RED}✖${_R}  ${_RED}Download failed.${_R}"
      return 1
    fi
    return 0
  fi

  # ── Mode: Audio M4A ──
  if [[ "$mode" == "audio-m4a" ]]; then
    echo -e "  ${_MAGENTA}♫${_R}  Downloading ${_B}audio (M4A/AAC)${_R} → ${_GRAY}$download_dir${_R}"
    echo ""

    local start_time=$SECONDS
    local dl_status=0

    (set -o pipefail; yt-dlp \
      "${cookie_args[@]}" \
      --no-playlist \
      -x --audio-format m4a --audio-quality 0 \
      --newline \
      -o "$download_dir/%(title).200s.%(ext)s" \
      "$url" 2>&1 | _ytd_progress) || dl_status=$?

    if [[ $dl_status -eq 0 ]]; then
      local elapsed=$(( SECONDS - start_time ))
      echo ""
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
      echo -e "  ${_GREEN}✔${_R}  ${_B}Audio download complete${_R}  ${_GRAY}(${elapsed}s)${_R}"
      echo -e "  ${_GRAY}   📁  $download_dir${_R}"
      echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"

      if [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"${video_title}\" with title \"Audio Download Complete\" sound name \"Glass\""
      fi
    else
      echo ""
      echo -e "  ${_RED}✖${_R}  ${_RED}Download failed.${_R}"
      return 1
    fi
    return 0
  fi

  # ── Mode: Interactive Format Picker ──
  echo -ne "  ${_CYAN}⟳${_R}  Fetching available formats..."

  local format_stdout stderr_file fetch_status
  stderr_file=$(mktemp)
  format_stdout=$(yt-dlp "${cookie_args[@]}" --no-playlist -F "$url" 2>"$stderr_file")
  fetch_status=$?

  echo -ne "\r\033[K"

  if [[ $fetch_status -ne 0 ]]; then
    echo -e "  ${_RED}✖${_R}  ${_RED}Could not fetch formats:${_R}"
    echo ""
    tail -n 6 "$stderr_file" | sed 's/^/     /'
    rm -f "$stderr_file"
    echo ""
    if [[ "$use_cookies" == false ]]; then
      echo -e "  ${_YELLOW}💡${_R}  ${_YELLOW}If this is a private or age-restricted video, retry with:${_R}"
      echo -e "     ${_GREEN}youtube -c ${url}${_R}"
    fi
    return 1
  fi

  rm -f "$stderr_file"

  local fzf_header
  fzf_header=$(printf '%s\n%s' \
    "  ▶ ${video_title}" \
    "  Use ↑↓ to navigate • Enter to select • Esc to cancel")

  local selected_line
  selected_line=$(
    echo "$format_stdout" |
    fzf \
      --tac \
      --reverse \
      --header="$fzf_header" \
      --prompt="  Format ❯ " \
      --pointer="▶" \
      --marker="●" \
      --color="fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#a6e3a1,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc,header:#94e2d5" \
      --border=rounded \
      --margin=1,2 \
      --padding=1,0
  )

  if [[ -z "$selected_line" ]]; then
    echo -e "  ${_YELLOW}✖${_R}  ${_YELLOW}Download cancelled.${_R}"
    return 0
  fi

  local format_code
  format_code=$(echo "$selected_line" | awk '{print $1}')

  if echo "$selected_line" | grep -iq "video only"; then
    echo -e "  ${_BLUE}ℹ${_R}  Video-only format — auto-merging with best audio."
    format_code="${format_code}+bestaudio"
  fi

  echo ""
  echo -e "  ${_GREEN}▶${_R}  Downloading format ${_B}$format_code${_R} → ${_GRAY}$download_dir${_R}"
  echo ""

  local start_time=$SECONDS
  local dl_status=0

  (set -o pipefail; yt-dlp \
    "${cookie_args[@]}" \
    --no-playlist \
    -f "$format_code" \
    --merge-output-format "$output_format" \
    --newline \
    -o "$download_dir/%(title).200s.%(ext)s" \
    "$url" 2>&1 | _ytd_progress) || dl_status=$?

  if [[ $dl_status -eq 0 ]]; then
    local elapsed=$(( SECONDS - start_time ))
    echo ""
    echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"
    echo -e "  ${_GREEN}✔${_R}  ${_B}Download complete${_R}  ${_GRAY}(${elapsed}s)${_R}"
    echo -e "  ${_GRAY}   📁  $download_dir${_R}"
    echo -e "  ${_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_R}"

    if [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1; then
      osascript -e "display notification \"${video_title}\" with title \"Download Complete\" sound name \"Glass\""
    fi
  else
    echo ""
    echo -e "  ${_RED}✖${_R}  ${_RED}Download failed.${_R}"
    return 1
  fi
}
FUNC_EOF

echo ""
success "Function ${BOLD}youtube${RESET} installed into ${BOLD}$RC_FILE${RESET}"
echo ""

# ── Post-Install Summary ──────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}  ┌─────────────────────────────────────────────────┐${RESET}"
echo -e "${CYAN}${BOLD}  │${RESET}  ${GREEN}✔  Installation complete!${RESET}${CYAN}${BOLD}                       │${RESET}"
echo -e "${CYAN}${BOLD}  └─────────────────────────────────────────────────┘${RESET}"
echo ""
echo -e "  ${BOLD}Quick Start:${RESET}"
echo ""
echo -e "    ${DIM}1.${RESET} Reload your shell:"
echo -e "       ${GREEN}source $RC_FILE${RESET}"
echo ""
echo -e "    ${DIM}2.${RESET} Download a video (interactive picker):"
echo -e "       ${GREEN}youtube https://youtu.be/dQw4w9WgXcQ${RESET}"
echo ""
echo -e "    ${DIM}3.${RESET} Quick-download best quality:"
echo -e "       ${GREEN}youtube -b https://youtu.be/dQw4w9WgXcQ${RESET}"
echo ""
echo -e "    ${DIM}4.${RESET} Download audio only (MP3):"
echo -e "       ${GREEN}youtube -a https://youtu.be/dQw4w9WgXcQ${RESET}"
echo ""
echo -e "    ${DIM}5.${RESET} See all options:"
echo -e "       ${GREEN}youtube --help${RESET}"
echo ""