o# YouTube Downloader CLI (Interactive)

A polished, interactive command-line tool to download YouTube videos directly from your terminal. Built with `yt-dlp`, `ffmpeg`, and `fzf` — with **zero Keychain/password prompts** by default.

## ✨ Features

- **🔓 Cookie-Free by Default** — No more macOS Keychain password prompts. Cookies are only used when you explicitly pass `-c` for private/age-restricted videos.
- **📋 Auto Playlist Detection** — Automatically detects playlist URLs and downloads all videos with numbered filenames into a dedicated folder. Asks for confirmation before downloading.
- **🖥️ Multi-Platform** — Auto-installs dependencies on **macOS** (Homebrew), **Linux** (apt/dnf/yum/pacman/zypper/apk/snap), and **Windows** (winget/scoop/choco via Git Bash).
- **🎯 Interactive Format Picker** — Beautiful `fzf`-powered format selector with a Catppuccin color theme. Navigate with arrow keys, select with Enter.
- **⚡ Smart Presets** — Skip the picker entirely with `-b` (best quality), `-a` (audio MP3), or `-m` (audio M4A).
- **🎬 Auto-Stitch Audio** — Selecting a high-res video-only format automatically merges it with the best available audio.
- **📊 Video Info Card** — Shows title, channel, and duration before you pick a format.
- **⏱️ Download Timer** — Displays elapsed time on completion.
- **🔔 Desktop Notifications** — Optional macOS notification on download completion (`-n` flag).
- **📁 Custom Output** — Choose your download directory (`-o`) and output format (`--mkv`).
- **🐚 Shell Auto-Detection** — Installs to `~/.zshrc` or `~/.bashrc` depending on your default shell.

## Installation

Run the installer directly from your terminal:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Anuradhapumudu/ytd/main/install-ytd.sh)
```

### What the installer does:

1. Detects your OS and installs `yt-dlp`, `ffmpeg`, and `fzf` if missing.
2. Detects your shell (`zsh` or `bash`) and injects the `youtube` function.
3. Removes any previously installed version to avoid duplicates.

## Usage

Reload your shell after installation:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

### Basic — Interactive Picker

```bash
youtube https://youtu.be/dQw4w9WgXcQ
```

A beautiful format picker appears. Use **↑↓** to navigate, **Enter** to select, **Esc** to cancel.

### Quick Download — Best Quality

```bash
youtube -b https://youtu.be/dQw4w9WgXcQ
```

### Audio Only — MP3 (320kbps)

```bash
youtube -a https://youtu.be/dQw4w9WgXcQ
```

### Audio Only — M4A/AAC

```bash
youtube -m https://youtu.be/dQw4w9WgXcQ
```

### Private / Age-Restricted Videos

```bash
youtube -c https://youtu.be/PRIVATE_VIDEO_ID
```

The `-c` flag enables browser cookie extraction. macOS may prompt for Keychain access (this is the **only** time it happens).

### All Options

| Flag | Description |
|------|-------------|
| `-b`, `--best` | Download best quality (skip picker) |
| `-a`, `--audio` | Download audio only (MP3, 320kbps) |
| `-m`, `--m4a` | Download audio only (M4A/AAC) |
| `-p`, `--playlist` | Force playlist mode (skip confirmation prompt) |
| `-c`, `--cookies` | Use browser cookies (private/restricted videos) |
| `-o`, `--output` DIR | Set download directory (default: `~/Downloads`) |
| `--mkv` | Output as MKV instead of MP4 |
| `-n`, `--notify` | Desktop notification on completion (macOS) |
| `--update` | Update to the latest version from GitHub |
| `--version` | Show current version |
| `-h`, `--help` | Show help |

### Examples

```bash
# Download to a specific folder
youtube -b -o ~/Videos https://youtu.be/dQw4w9WgXcQ

# Audio MP3 with notification
youtube -a -n https://youtu.be/dQw4w9WgXcQ

# Private video with cookies, output as MKV
youtube -c --mkv https://youtu.be/PRIVATE_ID
```

### Playlist Downloads

Playlists are **auto-detected** from the URL — no special flags needed:

```bash
# Auto-detected playlist → asks confirmation, downloads best quality
youtube -b https://youtube.com/playlist?list=PLxxxxxxxx

# Playlist with audio-only (MP3)
youtube -a https://youtube.com/playlist?list=PLxxxxxxxx

# Skip confirmation prompt with -p
youtube -p -b https://youtube.com/playlist?list=PLxxxxxxxx

# Video URL with playlist context (also auto-detected)
youtube -b "https://youtube.com/watch?v=xxx&list=PLxxxxxxxx"
```

Playlist files are saved as `001 - Title.mp4`, `002 - Title.mp4`, etc. inside a subfolder named after the playlist in your download directory.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **No audio in downloaded video** | Make sure `ffmpeg` is installed: `brew install ffmpeg` |
| **Only 1080p available** | Update yt-dlp: `brew upgrade yt-dlp` (or equivalent) |
| **Private video won't download** | Use the `-c` flag: `youtube -c <url>` |
| **Keychain prompt appears** | This only happens with `-c`. Without `-c`, cookies are never touched |
| **Cookie extraction fails** | Fully quit Chrome/Brave (`Cmd+Q`) before retrying with `-c` |
| **`fzf` not found** | Run the installer again, or: `brew install fzf` |

## Uninstalling

Remove the `youtube` function from your `~/.zshrc` (or `~/.bashrc`). Look for the block starting with `# YouTube Download (yt-dlp)` and delete everything through the closing `}`.
