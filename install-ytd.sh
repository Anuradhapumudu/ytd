#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# YouTube Downloader — Interactive CLI Installer  v2.3
# Installs yt-dlp, ffmpeg, fzf and injects the `youtube` shell function.
#
# Supports: macOS · Linux · WSL · Windows (Git Bash / MSYS2)
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Anuradhapumudu/ytd/main/install-ytd.sh)
# ─────────────────────────────────────────────────────────────────────────────

# ── Safety: do NOT use set -e — it causes silent failures on Windows/WSL ──
# We handle errors explicitly instead.

# ── Portable printf-based helpers (echo -e is not portable) ──────────────────
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
BLUE='\033[34m'
RESET='\033[0m'

p()       { printf '%b\n' "$*"; }
info()    { printf '  \033[34mINFO\033[0m  %b\n' "$1"; }
success() { printf '  \033[32m OK \033[0m  %b\n' "$1"; }
warn()    { printf '  \033[33mWARN\033[0m  %b\n' "$1"; }
fail()    { printf '  \033[31mFAIL\033[0m  %b\n' "$1"; }

# ── Banner ────────────────────────────────────────────────────────────────────
p ""
p "${CYAN}${BOLD}  =============================================${RESET}"
p "${CYAN}${BOLD}       YouTube Downloader  CLI  v2.3${RESET}"
p "${CYAN}${BOLD}  =============================================${RESET}"
p ""

# ── Detect environment ────────────────────────────────────────────────────────
detect_env() {
  # WSL must be checked before generic linux
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
    return
  fi
  case "${OSTYPE:-}" in
    darwin*)             echo "mac" ;;
    msys*|cygwin*|win*) echo "windows" ;;
    linux*)              echo "linux" ;;
    *)
      # Last resort: check uname
      case "$(uname -s 2>/dev/null)" in
        Darwin)  echo "mac" ;;
        Linux)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)       echo "unknown" ;;
      esac
      ;;
  esac
}

ENV="$(detect_env)"
info "Detected environment: ${BOLD}${ENV}${RESET}"
p ""

# ── Detect RC file ────────────────────────────────────────────────────────────
detect_rc() {
  local sh
  sh="$(basename "${SHELL:-bash}" 2>/dev/null || echo bash)"
  case "$sh" in
    zsh)  echo "${HOME}/.zshrc" ;;
    fish) echo "${HOME}/.config/fish/config.fish" ;;
    *)
      # On WSL/Windows bash is typical; prefer .bashrc
      if [[ -f "${HOME}/.bashrc" ]]; then
        echo "${HOME}/.bashrc"
      elif [[ -f "${HOME}/.zshrc" ]]; then
        echo "${HOME}/.zshrc"
      else
        echo "${HOME}/.bashrc"
      fi
      ;;
  esac
}

RC_FILE="$(detect_rc)"

# ── command_exists helper ─────────────────────────────────────────────────────
command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── yt-dlp special: can also be a Python package ─────────────────────────────
ytdlp_exists() {
  command_exists yt-dlp && return 0
  python3 -m yt_dlp --version >/dev/null 2>&1 && return 0
  return 1
}

# ── Install helpers per platform ──────────────────────────────────────────────
install_mac() {
  local pkg="$1"
  if command_exists brew; then
    brew install "$pkg" 2>&1 | tail -3
  else
    fail "Homebrew not found. Install it from ${CYAN}https://brew.sh${RESET}"
    return 1
  fi
}

install_linux() {
  local pkg="$1"
  if command_exists apt-get; then
    sudo apt-get update -qq 2>/dev/null && sudo apt-get install -y "$pkg" 2>&1 | tail -3
  elif command_exists dnf; then
    sudo dnf install -y "$pkg" 2>&1 | tail -3
  elif command_exists yum; then
    sudo yum install -y "$pkg" 2>&1 | tail -3
  elif command_exists pacman; then
    sudo pacman -Sy --noconfirm "$pkg" 2>&1 | tail -3
  elif command_exists zypper; then
    sudo zypper --non-interactive install "$pkg" 2>&1 | tail -3
  elif command_exists apk; then
    sudo apk add "$pkg" 2>&1 | tail -3
  elif command_exists brew; then
    brew install "$pkg" 2>&1 | tail -3
  else
    return 1
  fi
}

# WSL uses Linux package managers but we may need pip fallback for yt-dlp
install_wsl() {
  install_linux "$1"
}

install_windows() {
  local pkg="$1"
  # Map generic package name to winget/scoop IDs
  local winget_id scoop_id
  case "$pkg" in
    yt-dlp)  winget_id="yt-dlp.yt-dlp";    scoop_id="yt-dlp" ;;
    ffmpeg)  winget_id="Gyan.FFmpeg";        scoop_id="ffmpeg" ;;
    fzf)     winget_id="junegunn.fzf";       scoop_id="fzf" ;;
    *)       winget_id="$pkg";               scoop_id="$pkg" ;;
  esac

  if command_exists winget; then
    winget install --id "$winget_id" --accept-source-agreements --accept-package-agreements 2>&1 | tail -5
    return 0
  elif command_exists scoop; then
    scoop install "$scoop_id" 2>&1 | tail -5
    return 0
  elif command_exists choco; then
    choco install "$scoop_id" -y 2>&1 | tail -5
    return 0
  else
    return 1
  fi
}

# ── pip fallback for yt-dlp when OS package manager doesn't have it ──────────
install_ytdlp_pip() {
  if command_exists pip3; then
    pip3 install -U yt-dlp 2>&1 | tail -3 && return 0
  elif command_exists pip; then
    pip install -U yt-dlp 2>&1 | tail -3 && return 0
  fi
  return 1
}

# ── Ensure a package is installed ─────────────────────────────────────────────
ensure_installed() {
  local name="$1"
  local check_fn="${2:-command_exists}"   # optional custom checker

  if $check_fn "$name" 2>/dev/null; then
    success "${BOLD}${name}${RESET} already installed"
    return 0
  fi

  warn "${BOLD}${name}${RESET} not found — installing..."

  local ok=false
  case "$ENV" in
    mac)     install_mac     "$name" && ok=true ;;
    linux)   install_linux   "$name" && ok=true ;;
    wsl)     install_wsl     "$name" && ok=true ;;
    windows) install_windows "$name" && ok=true ;;
  esac

  # yt-dlp pip fallback
  if [[ "$ok" == false && "$name" == "yt-dlp" ]]; then
    warn "Trying pip install for yt-dlp..."
    install_ytdlp_pip && ok=true
  fi

  if $check_fn "$name" 2>/dev/null; then
    success "${BOLD}${name}${RESET} installed"
    return 0
  fi

  if [[ "$ok" == false ]]; then
    fail "Could not install ${BOLD}${name}${RESET}. Please install it manually."
    p "  See: ${CYAN}https://github.com/yt-dlp/yt-dlp#installation${RESET}"
    return 1
  fi
}

# ── Install Dependencies ──────────────────────────────────────────────────────
p "${BOLD}  Installing dependencies...${RESET}"
p ""

ensure_installed yt-dlp ytdlp_exists || true
ensure_installed ffmpeg             || true

# fzf is optional — interactive mode needs it, presets (-b/-a/-m) don't
if ! command_exists fzf; then
  warn "fzf not found — interactive format picker will be unavailable."
  warn "Install fzf manually or use -b / -a / -m flags to skip the picker."
else
  success "${BOLD}fzf${RESET} already installed"
fi

p ""

# ── Prepare RC file ───────────────────────────────────────────────────────────
if [[ ! -f "$RC_FILE" ]]; then
  touch "$RC_FILE" 2>/dev/null || true
fi
info "Shell config: ${BOLD}${RC_FILE}${RESET}"

# ── Remove old function block (portable — no mktemp path issues) ──────────────
# Strip from "# YouTube Download" comment to the closing "}" of the function.
# Written to a temp file then moved, with Windows-safe path handling.
_tmp_rc="${RC_FILE}.ytd_tmp"
awk '
  /^# YouTube Download \(yt-dlp\)/ { skip=1 }
  skip && /^}$/ { skip=0; next }
  !skip { print }
' "$RC_FILE" > "$_tmp_rc" 2>/dev/null && mv "$_tmp_rc" "$RC_FILE" 2>/dev/null || true

# ── Inject the youtube() Function ────────────────────────────────────────────
cat >> "$RC_FILE" << 'FUNC_EOF'

# YouTube Download (yt-dlp) — v2.3
# Cookie-free. Auto-detects playlists. Visual progress bar. Auto-update.
function youtube() {

  # ── Version / Update endpoint ──
  local YTD_VERSION="2.3"
  local YTD_RAW="https://raw.githubusercontent.com/Anuradhapumudu/ytd/main/install-ytd.sh"

  # ── Portable printf wrappers ──
  local _R='\033[0m' _B='\033[1m'
  local _GREEN='\033[32m' _CYAN='\033[36m' _YELLOW='\033[33m'
  local _RED='\033[31m'   _BLUE='\033[34m'  _MAGENTA='\033[35m'
  local _GRAY='\033[90m'  _WHITE='\033[97m'

  _ytd_line()  { printf '  %b-----------------------------------------------------%b\n' "$1" "$_R"; }
  _ytd_ok()    { printf '  %b OK %b  %b\n' "$_GREEN" "$_R" "$1"; }
  _ytd_info()  { printf '  %b    %b  %b\n' "$_CYAN"  "$_R" "$1"; }
  _ytd_warn()  { printf '  %b WRN%b  %b\n' "$_YELLOW" "$_R" "$1"; }
  _ytd_fail()  { printf '  %b ERR%b  %b\n' "$_RED"   "$_R" "$1"; }

  # ── Progress Bar Renderer ──
  # Single-line. No \n ever. Pure string ops — no grep/sed subprocesses.
  # All locals declared at top to prevent zsh variable-leak in pipe subshells.
  _ytd_progress() {
    local _bw=40 _last=-1
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
            _j=0; while [[ $_j -lt $_f ]]; do _bar="${_bar}#"; _j=$((_j+1)); done
            _j=0; while [[ $_j -lt $_e ]]; do _bar="${_bar}-"; _j=$((_j+1)); done
            if [[ $_pct -ge 100 ]]; then
              printf '\r\033[K  \033[32m[%s]\033[0m \033[1m100%%\033[0m  \033[90mDone\033[0m     ' "$_bar"
            else
              _sz="..."; _sp="..."; _et="..."
              case "$_ln" in *" of "*) _tmp="${_ln#* of }"; _tmp="${_tmp#\~ }"; _tmp="${_tmp# }"; _sz="${_tmp%% *}";; esac
              case "$_ln" in *" at "*) _tmp="${_ln#* at }"; _tmp="${_tmp# }"; _sp="${_tmp%% *}";; esac
              case "$_ln" in *"ETA "*) _tmp="${_ln#*ETA }";  _et="${_tmp%% *}";; esac
              printf '\r\033[K  \033[32m[%s]\033[0m \033[1m%3d%%\033[0m  \033[90m%s  %s  ETA %s\033[0m' \
                "$_bar" "$_pct" "$_sz" "$_sp" "$_et"
            fi
          fi
          ;;
        "[Merger]"*)     printf '\r\033[K  [~] Merging video + audio...' ;;
        "[ExtractAudio]"*) printf '\r\033[K  [~] Extracting audio...' ;;
        "[download] Downloading"*)
          _tmp="${_ln#\[download\] }"
          printf '\r\033[K  [>] %s' "$_tmp"
          _last=-1 ;;
        "[download] Destination:"*) _last=-1 ;;
        "[download]"*"already been downloaded"*)
          printf '\r\033[K  [=] Skipping (already downloaded)' ;;
      esac
    done
    printf '\r\033[K'
  }

  # ── Argument Parsing ──
  local use_cookies=false mode="interactive" output_format="mp4"
  local download_dir="$HOME/Downloads" notify=false force_playlist=false url=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        printf '\n%b  YouTube Downloader  v%s%b\n\n' "$_CYAN$_B" "$YTD_VERSION" "$_R"
        printf '  %bUSAGE%b\n    youtube [options] <url>\n\n' "$_B" "$_R"
        printf '  %bOPTIONS%b\n' "$_B" "$_R"
        printf '    %b-b%b, %b--best%b       Download best quality (skip picker)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b-a%b, %b--audio%b      Audio only (MP3 320kbps)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b-m%b, %b--m4a%b        Audio only (M4A/AAC)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b-p%b, %b--playlist%b   Force playlist mode (skip confirmation)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b-c%b, %b--cookies%b    Use browser cookies (private/restricted)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b-o%b, %b--output%b DIR Download directory (default: ~/Downloads)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b--mkv%b               Output as MKV\n' "$_GREEN" "$_R"
        printf '    %b-n%b, %b--notify%b     Desktop notification on completion (macOS)\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '    %b--update%b            Update to latest version from GitHub\n' "$_GREEN" "$_R"
        printf '    %b--version%b           Show version\n' "$_GREEN" "$_R"
        printf '    %b-h%b, %b--help%b       Show this help\n\n' "$_GREEN" "$_R" "$_GREEN" "$_R"
        printf '  %bEXAMPLES%b\n' "$_B" "$_R"
        printf '    youtube https://youtu.be/dQw4w9WgXcQ\n'
        printf '    youtube -b https://youtu.be/dQw4w9WgXcQ\n'
        printf '    youtube -a https://youtu.be/dQw4w9WgXcQ\n'
        printf '    youtube -b https://youtube.com/playlist?list=PLxxxxxx\n\n'
        return 0 ;;
      -b|--best)     mode="best";      shift ;;
      -a|--audio)    mode="audio-mp3"; shift ;;
      -m|--m4a)      mode="audio-m4a"; shift ;;
      -p|--playlist) force_playlist=true; shift ;;
      -c|--cookies)  use_cookies=true;    shift ;;
      -o|--output)
        if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
          download_dir="$2"; shift 2
        else
          _ytd_fail "--output requires a directory path"; return 1
        fi ;;
      --mkv)     output_format="mkv"; shift ;;
      -n|--notify) notify=true;       shift ;;
      --update)
        printf '\n  [~] Checking for updates...\n\n'
        local _upd_tmp
        _upd_tmp=$(mktemp 2>/dev/null || printf '%s' "${TMPDIR:-/tmp}/ytd_update_$$.sh")
        if curl -fsSL --max-time 30 "$YTD_RAW" -o "$_upd_tmp" 2>/dev/null \
           && [[ -s "$_upd_tmp" ]]; then
          bash "$_upd_tmp"
          rm -f "$_upd_tmp" 2>/dev/null || true
          rm -f "$HOME/.ytd_update_notice" 2>/dev/null || true
          printf '\n  %b[OK]%b Updated! Reload your shell to apply.\n\n' "$_GREEN" "$_R"
        else
          rm -f "$_upd_tmp" 2>/dev/null || true
          _ytd_fail "Update failed. Check your internet connection."
        fi
        return 0 ;;
      --version)
        printf '  YouTube Downloader %bv%s%b\n' "$_B" "$YTD_VERSION" "$_R"
        return 0 ;;
      -*)
        _ytd_fail "Unknown option: $1  (run 'youtube --help' for usage)"
        return 1 ;;
      *) url="$1"; shift ;;
    esac
  done

  # ── Background auto-update check (once per 24 h) ──────────────────────────
  (
    local _cf="$HOME/.ytd_last_check" _nf="$HOME/.ytd_update_notice"
    local _now _last _remote
    _now=$(date +%s 2>/dev/null) || _now=0
    _last=0; [[ -f "$_cf" ]] && _last=$(cat "$_cf" 2>/dev/null || echo 0)
    if (( _now - _last > 86400 )); then
      printf '%s' "$_now" > "$_cf" 2>/dev/null || true
      _remote=$(curl -fsSL --max-time 5 "$YTD_RAW" 2>/dev/null \
                | grep -m1 'YTD_VERSION=' | cut -d'"' -f2)
      if [[ -n "$_remote" && "$_remote" != "$YTD_VERSION" ]]; then
        printf '%s' "$_remote" > "$_nf" 2>/dev/null || true
      else
        rm -f "$_nf" 2>/dev/null || true
      fi
    fi
  ) >/dev/null 2>&1 &
  { disown 2>/dev/null || true; } 2>/dev/null || true

  # Show pending update notice
  if [[ -f "$HOME/.ytd_update_notice" ]]; then
    local _nv; _nv=$(cat "$HOME/.ytd_update_notice" 2>/dev/null || true)
    if [[ -n "$_nv" && "$_nv" != "$YTD_VERSION" ]]; then
      printf '  %b[^]%b  Update available: v%s  (run: youtube --update)\n\n' \
        "$_YELLOW" "$_R" "$_nv"
    fi
  fi

  # ── Validate URL ──────────────────────────────────────────────────────────
  if [[ -z "$url" ]]; then
    printf '\n  %bYouTube Downloader  v%s%b\n\n' "$_CYAN$_B" "$YTD_VERSION" "$_R"
    _ytd_fail "No URL provided.  Usage: youtube [options] <url>"
    printf '  Run %byoutube --help%b for full usage.\n\n' "$_GREEN" "$_R"
    return 1
  fi

  # ── Check dependencies ────────────────────────────────────────────────────
  local _missing=()
  command -v yt-dlp >/dev/null 2>&1 || _missing+=(yt-dlp)
  command -v ffmpeg  >/dev/null 2>&1 || _missing+=(ffmpeg)
  [[ "$mode" == "interactive" ]] && { command -v fzf >/dev/null 2>&1 || _missing+=(fzf); }
  if [[ ${#_missing[@]} -gt 0 ]]; then
    _ytd_fail "Missing: ${_missing[*]}.  Re-run the installer."
    return 1
  fi

  # ── Cookie args ───────────────────────────────────────────────────────────
  local cookie_args=()
  if [[ "$use_cookies" == true ]]; then
    local _browser=""
    command -v google-chrome       >/dev/null 2>&1 && _browser="chrome"
    command -v google-chrome-stable>/dev/null 2>&1 && _browser="chrome"
    command -v chromium            >/dev/null 2>&1 && _browser="${_browser:-chromium}"
    command -v chromium-browser    >/dev/null 2>&1 && _browser="${_browser:-chromium}"
    command -v brave-browser       >/dev/null 2>&1 && _browser="${_browser:-brave}"
    command -v firefox             >/dev/null 2>&1 && _browser="${_browser:-firefox}"
    [[ -d "/Applications/Google Chrome.app" ]] && _browser="chrome"
    [[ -d "/Applications/Brave Browser.app" ]] && _browser="${_browser:-brave}"

    if [[ -n "$_browser" ]]; then
      cookie_args=(--cookies-from-browser "$_browser")
      _ytd_info "Using ${_browser} cookies"
    else
      _ytd_warn "No supported browser found — continuing without cookies"
    fi
  fi

  mkdir -p "$download_dir" 2>/dev/null || true

  # ── Playlist detection ─────────────────────────────────────────────────────
  local is_playlist=false
  [[ "$url" == *"playlist?list="* ]] && is_playlist=true
  [[ "$url" == *"&list="*         ]] && is_playlist=true
  [[ "$url" == *"?list="*         ]] && is_playlist=true
  [[ "$url" == *"/sets/"*         ]] && is_playlist=true
  [[ "$force_playlist" == true    ]] && is_playlist=true

  # ═══════════════════════════════════════════════════════════════════════════
  # PLAYLIST MODE
  # ═══════════════════════════════════════════════════════════════════════════
  if [[ "$is_playlist" == true ]]; then
    printf '\n'
    printf '  [~] Scanning playlist...'

    local _pl_info _pl_title _pl_count
    _pl_info=$(yt-dlp "${cookie_args[@]}" --flat-playlist --dump-json "$url" 2>/dev/null || true)

    if [[ -z "$_pl_info" ]]; then
      printf '\r\033[K'
      _ytd_fail "Could not fetch playlist info."
      [[ "$use_cookies" == false ]] && printf '  Tip: retry with %b-c%b for private playlists\n' "$_GREEN" "$_R"
      return 1
    fi

    _pl_count=$(printf '%s\n' "$_pl_info" | wc -l | tr -d ' ')
    _pl_title=$(printf '%s\n' "$_pl_info" | head -1 \
      | grep -o '"playlist_title":"[^"]*"' | head -1 | cut -d'"' -f4)
    [[ -z "$_pl_title" ]] && _pl_title="Playlist"

    printf '\r\033[K'
    printf '\n'
    _ytd_line "$_MAGENTA"
    printf '  %b  [=] %s%b\n' "$_B$_WHITE" "$_pl_title" "$_R"
    printf '  %b      %s videos%b\n' "$_GRAY" "$_pl_count" "$_R"
    _ytd_line "$_MAGENTA"
    printf '\n'

    # Confirmation
    if [[ "$force_playlist" == false ]]; then
      local _cm
      case "$mode" in
        best)      _cm="best quality" ;;
        audio-mp3) _cm="audio (MP3)"  ;;
        audio-m4a) _cm="audio (M4A)"  ;;
        *)         _cm="best quality"; mode="best" ;;
      esac
      printf '  [?] Download all %b%s%b videos as %b%s%b? [Y/n] ' \
        "$_B" "$_pl_count" "$_R" "$_B" "$_cm" "$_R"
      local _ans; read -r _ans
      case "$_ans" in [nN]*) _ytd_warn "Cancelled."; return 0 ;; esac
    fi
    [[ "$mode" == "interactive" ]] && mode="best"

    local _pl_dir="${download_dir}/${_pl_title}"
    mkdir -p "$_pl_dir" 2>/dev/null || true

    local _dl_lbl
    case "$mode" in
      best)      _dl_lbl="best quality" ;;
      audio-mp3) _dl_lbl="audio MP3"    ;;
      audio-m4a) _dl_lbl="audio M4A"   ;;
    esac

    printf '\n'
    _ytd_info "Downloading ${_B}${_pl_count} videos${_R} — ${_B}${_dl_lbl}${_R}"
    _ytd_info "Saving to: ${_GRAY}${_pl_dir}${_R}"
    printf '\n'

    local _t0=$SECONDS _dls=0

    case "$mode" in
      best)
        { yt-dlp "${cookie_args[@]}" --yes-playlist \
            -f "bestvideo+bestaudio/best" \
            --merge-output-format "$output_format" \
            --newline \
            -o "${_pl_dir}/%(playlist_index)03d - %(title).180s.%(ext)s" \
            "$url" 2>&1; } | _ytd_progress || _dls=$?
        ;;
      audio-mp3)
        { yt-dlp "${cookie_args[@]}" --yes-playlist \
            -x --audio-format mp3 --audio-quality 0 \
            --newline \
            -o "${_pl_dir}/%(playlist_index)03d - %(title).180s.%(ext)s" \
            "$url" 2>&1; } | _ytd_progress || _dls=$?
        ;;
      audio-m4a)
        { yt-dlp "${cookie_args[@]}" --yes-playlist \
            -x --audio-format m4a --audio-quality 0 \
            --newline \
            -o "${_pl_dir}/%(playlist_index)03d - %(title).180s.%(ext)s" \
            "$url" 2>&1; } | _ytd_progress || _dls=$?
        ;;
    esac

    local _elapsed=$(( SECONDS - _t0 ))
    local _fc; _fc=$(find "$_pl_dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')

    printf '\n'
    if [[ $_dls -eq 0 ]]; then
      _ytd_line "$_GREEN"
      _ytd_ok  "${_B}Playlist download complete${_R}  ${_GRAY}(${_elapsed}s)${_R}"
      _ytd_info "${_GRAY}${_fc} files  ->  ${_pl_dir}${_R}"
      _ytd_line "$_GREEN"
      [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1 && \
        osascript -e "display notification \"${_pl_title}\" with title \"Download Complete\" sound name \"Glass\"" 2>/dev/null || true
    else
      _ytd_line "$_YELLOW"
      _ytd_warn "${_B}Download finished with some errors${_R}  ${_GRAY}(${_elapsed}s)${_R}"
      _ytd_info "${_GRAY}${_fc} files  ->  ${_pl_dir}${_R}"
      _ytd_line "$_YELLOW"
    fi
    return 0
  fi

  # ═══════════════════════════════════════════════════════════════════════════
  # SINGLE VIDEO MODE
  # ═══════════════════════════════════════════════════════════════════════════

  # Fetch info
  printf '\n  [~] Fetching video info...'

  local _vtitle="Unknown Title" _vchan="Unknown" _vdur="?"
  local _vinfo
  _vinfo=$(yt-dlp "${cookie_args[@]}" --no-playlist \
    --print "%(title)s" \
    --print "%(channel)s" \
    --print "%(duration_string)s" \
    "$url" 2>/dev/null || true)

  if [[ -n "$_vinfo" ]]; then
    _vtitle=$(printf '%s\n' "$_vinfo" | sed -n '1p')
    _vchan=$(printf '%s\n'  "$_vinfo" | sed -n '2p')
    _vdur=$(printf '%s\n'   "$_vinfo" | sed -n '3p')
  fi
  [[ -z "$_vtitle" ]] && _vtitle="Unknown Title"
  [[ -z "$_vchan"  ]] && _vchan="Unknown"
  [[ -z "$_vdur"   ]] && _vdur="?"

  printf '\r\033[K'

  # Info card
  _ytd_line "$_CYAN"
  printf '  %b  %s%b\n'  "$_B$_WHITE" "$_vtitle" "$_R"
  printf '  %b  %s  *  %s%b\n' "$_GRAY" "$_vchan" "$_vdur" "$_R"
  _ytd_line "$_CYAN"
  printf '\n'

  # ── Mode: Best ─────────────────────────────────────────────────────────────
  if [[ "$mode" == "best" ]]; then
    _ytd_info "Downloading ${_B}best quality${_R} -> ${_GRAY}${download_dir}${_R}"
    printf '\n'
    local _t0=$SECONDS _dls=0
    { yt-dlp "${cookie_args[@]}" --no-playlist \
        -f "bestvideo+bestaudio/best" \
        --merge-output-format "$output_format" \
        --newline \
        -o "${download_dir}/%(title).200s.%(ext)s" \
        "$url" 2>&1; } | _ytd_progress || _dls=$?
    if [[ $_dls -eq 0 ]]; then
      local _e=$(( SECONDS - _t0 ))
      printf '\n'; _ytd_line "$_GREEN"
      _ytd_ok "${_B}Download complete${_R}  ${_GRAY}(${_e}s)${_R}"
      _ytd_info "${_GRAY}${download_dir}${_R}"
      _ytd_line "$_GREEN"
      [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1 && \
        osascript -e "display notification \"${_vtitle}\" with title \"Download Complete\" sound name \"Glass\"" 2>/dev/null || true
    else
      printf '\n'; _ytd_fail "Download failed."
      return 1
    fi
    return 0
  fi

  # ── Mode: Audio MP3 ────────────────────────────────────────────────────────
  if [[ "$mode" == "audio-mp3" ]]; then
    _ytd_info "Downloading ${_B}audio (MP3 320kbps)${_R} -> ${_GRAY}${download_dir}${_R}"
    printf '\n'
    local _t0=$SECONDS _dls=0
    { yt-dlp "${cookie_args[@]}" --no-playlist \
        -x --audio-format mp3 --audio-quality 0 \
        --newline \
        -o "${download_dir}/%(title).200s.%(ext)s" \
        "$url" 2>&1; } | _ytd_progress || _dls=$?
    if [[ $_dls -eq 0 ]]; then
      local _e=$(( SECONDS - _t0 ))
      printf '\n'; _ytd_line "$_GREEN"
      _ytd_ok "${_B}Audio download complete${_R}  ${_GRAY}(${_e}s)${_R}"
      _ytd_info "${_GRAY}${download_dir}${_R}"
      _ytd_line "$_GREEN"
      [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1 && \
        osascript -e "display notification \"${_vtitle}\" with title \"Download Complete\" sound name \"Glass\"" 2>/dev/null || true
    else
      printf '\n'; _ytd_fail "Download failed."
      return 1
    fi
    return 0
  fi

  # ── Mode: Audio M4A ────────────────────────────────────────────────────────
  if [[ "$mode" == "audio-m4a" ]]; then
    _ytd_info "Downloading ${_B}audio (M4A/AAC)${_R} -> ${_GRAY}${download_dir}${_R}"
    printf '\n'
    local _t0=$SECONDS _dls=0
    { yt-dlp "${cookie_args[@]}" --no-playlist \
        -x --audio-format m4a --audio-quality 0 \
        --newline \
        -o "${download_dir}/%(title).200s.%(ext)s" \
        "$url" 2>&1; } | _ytd_progress || _dls=$?
    if [[ $_dls -eq 0 ]]; then
      local _e=$(( SECONDS - _t0 ))
      printf '\n'; _ytd_line "$_GREEN"
      _ytd_ok "${_B}Audio download complete${_R}  ${_GRAY}(${_e}s)${_R}"
      _ytd_info "${_GRAY}${download_dir}${_R}"
      _ytd_line "$_GREEN"
      [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1 && \
        osascript -e "display notification \"${_vtitle}\" with title \"Download Complete\" sound name \"Glass\"" 2>/dev/null || true
    else
      printf '\n'; _ytd_fail "Download failed."
      return 1
    fi
    return 0
  fi

  # ── Mode: Interactive fzf picker ───────────────────────────────────────────
  printf '  [~] Fetching available formats...'
  local _fmts _fstatus=0
  _fmts=$(yt-dlp "${cookie_args[@]}" --no-playlist -F "$url" 2>/dev/null) || _fstatus=$?
  printf '\r\033[K'

  if [[ $_fstatus -ne 0 || -z "$_fmts" ]]; then
    _ytd_fail "Could not fetch formats."
    [[ "$use_cookies" == false ]] && printf '  Tip: retry with %b-c%b for private/age-restricted videos\n' "$_GREEN" "$_R"
    return 1
  fi

  local _sel
  _sel=$(printf '%s\n' "$_fmts" | fzf \
    --tac --reverse \
    --header="  $(printf '%s' "$_vtitle")
  Use arrow keys to select, Enter to confirm, Esc to cancel" \
    --prompt="  Format > " \
    --color="fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,\
info:#cba6f7,prompt:#a6e3a1,pointer:#f5e0dc,marker:#f5e0dc,spinner:#f5e0dc,header:#94e2d5" \
    --border=rounded --margin=1,2 --padding=1,0) || true

  if [[ -z "$_sel" ]]; then
    _ytd_warn "Download cancelled."
    return 0
  fi

  local _fmt
  _fmt=$(printf '%s\n' "$_sel" | awk '{print $1}')
  printf '%s\n' "$_sel" | grep -qi "video only" && _fmt="${_fmt}+bestaudio"

  printf '\n'
  _ytd_info "Downloading format ${_B}${_fmt}${_R} -> ${_GRAY}${download_dir}${_R}"
  printf '\n'

  local _t0=$SECONDS _dls=0
  { yt-dlp "${cookie_args[@]}" --no-playlist \
      -f "$_fmt" \
      --merge-output-format "$output_format" \
      --newline \
      -o "${download_dir}/%(title).200s.%(ext)s" \
      "$url" 2>&1; } | _ytd_progress || _dls=$?

  if [[ $_dls -eq 0 ]]; then
    local _e=$(( SECONDS - _t0 ))
    printf '\n'; _ytd_line "$_GREEN"
    _ytd_ok "${_B}Download complete${_R}  ${_GRAY}(${_e}s)${_R}"
    _ytd_info "${_GRAY}${download_dir}${_R}"
    _ytd_line "$_GREEN"
    [[ "$notify" == true ]] && command -v osascript >/dev/null 2>&1 && \
      osascript -e "display notification \"${_vtitle}\" with title \"Download Complete\" sound name \"Glass\"" 2>/dev/null || true
  else
    printf '\n'; _ytd_fail "Download failed."
    return 1
  fi
}
FUNC_EOF

# ── Done ──────────────────────────────────────────────────────────────────────
p ""
success "Function ${BOLD}youtube${RESET} installed into ${BOLD}${RC_FILE}${RESET}"
p ""
p "${CYAN}${BOLD}  ==============================================${RESET}"
p "${GREEN}${BOLD}     Installation complete!${RESET}"
p "${CYAN}${BOLD}  ==============================================${RESET}"
p ""
p "  ${BOLD}Next steps:${RESET}"
p ""
p "  1. Reload your shell:"
p "     ${GREEN}source ${RC_FILE}${RESET}"
p ""
p "  2. Download a video (interactive picker):"
p "     ${GREEN}youtube https://youtu.be/dQw4w9WgXcQ${RESET}"
p ""
p "  3. Best quality, no picker:"
p "     ${GREEN}youtube -b https://youtu.be/dQw4w9WgXcQ${RESET}"
p ""
p "  4. Audio only (MP3):"
p "     ${GREEN}youtube -a https://youtu.be/dQw4w9WgXcQ${RESET}"
p ""
p "  5. See all options:"
p "     ${GREEN}youtube --help${RESET}"
p ""