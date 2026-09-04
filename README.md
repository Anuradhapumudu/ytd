# YouTube Downloader CLI

A polished, cross-platform command-line tool to download YouTube videos directly from your terminal. Built with `yt-dlp`, `ffmpeg`, and `fzf` — works on **macOS, Linux, WSL, and Windows**.

## Features

- **Cookie-Free by Default** — No Keychain/password prompts. Cookies only used with `-c` flag.
- **Auto Playlist Detection** — Detects playlist URLs automatically, downloads all videos with numbered filenames.
- **Cross-Platform** — macOS (Homebrew), Linux (apt/dnf/yum/pacman/zypper/apk), WSL, Windows (winget/scoop/choco via Git Bash/MSYS2).
- **Visual Progress Bar** — Single-line progress bar with speed, ETA, and percentage. No spammy output.
- **Interactive Format Picker** — `fzf`-powered format selector with Catppuccin theme (optional — presets work without fzf).
- **Smart Presets** — `-b` (best quality), `-a` (audio MP3), `-m` (audio M4A) — skip the picker entirely.
- **Auto-Update** — Checks for new versions in the background once per 24h. Update with `youtube --update`.
- **Auto-Stitch Audio** — Video-only formats are automatically merged with the best available audio.
- **Video Info Card** — Shows title, channel, and duration before format selection.
- **Download Timer** — Elapsed time shown on completion.
- **Desktop Notifications** — Optional macOS notification on completion (`-n` flag).
- **Custom Output** — Choose download directory (`-o`) and output format (`--mkv`).
- **Shell Auto-Detection** — Installs to `~/.zshrc` or `~/.bashrc` depending on your shell.

## Installation

Run the installer directly from your terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Anuradhapumudu/ytd/main/install-ytd.sh)
```

### Windows (PowerShell)

PowerShell does **not** support `bash <(...)`. Use this instead:

```powershell
curl.exe -fsSL https://raw.githubusercontent.com/Anuradhapumudu/ytd/main/install-ytd.sh | wsl bash
```

> **Note:** This requires [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) to be installed. Alternatively, open **Git Bash** or **WSL terminal** directly and run the macOS/Linux command above.

### Windows (Git Bash / WSL Terminal)

Open Git Bash or your WSL terminal (not PowerShell), then run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Anuradhapumudu/ytd/main/install-ytd.sh)
```

### What the installer does

1. Detects your OS (macOS / Linux / WSL / Windows Git Bash).
2. Installs `yt-dlp`, `ffmpeg`, and `fzf` using your system's package manager.
3. Falls back to `pip` for `yt-dlp` if the package manager doesn't have it.
4. Detects your shell (`zsh` or `bash`) and injects the `youtube` function.
5. Removes any previously installed version to avoid duplicates.

### Platform-Specific Notes

| Platform | Package Manager | Shell | Install From |
|----------|----------------|-------|-------------|
| macOS | Homebrew | zsh (default) or bash | Terminal |
| Ubuntu / Debian | apt | bash or zsh | Terminal |
| Fedora / RHEL | dnf / yum | bash or zsh | Terminal |
| Arch | pacman | bash or zsh | Terminal |
| Alpine | apk | bash or zsh | Terminal |
| WSL | apt / dnf (depends on distro) | bash | WSL Terminal |
| Windows (Git Bash) | winget / scoop / choco | bash | Git Bash |
| Windows (MSYS2) | winget / scoop / choco | bash | MSYS2 |
| Windows | winget (via WSL) | bash | PowerShell |

## Usage

Reload your shell after installation:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

### Basic — Interactive Picker

```bash
youtube https://youtu.be/dQw4w9WgXcQ
```

A format picker appears. Use arrow keys to navigate, Enter to select, Esc to cancel.

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
# Auto-detected playlist — asks confirmation, downloads best quality
youtube -b https://youtube.com/playlist?list=PLxxxxxxxx

# Playlist with audio-only (MP3)
youtube -a https://youtube.com/playlist?list=PLxxxxxxxx

# Skip confirmation prompt with -p
youtube -p -b https://youtube.com/playlist?list=PLxxxxxxxx

# Video URL with playlist context (also auto-detected)
youtube -b "https://youtube.com/watch?v=xxx&list=PLxxxxxxxx"
```

Playlist files are saved as `001 - Title.mp4`, `002 - Title.mp4`, etc. inside a subfolder named after the playlist.

### Updating

The script checks for updates in the background once per 24 hours. When a new version is available, you'll see a notice:

```
  [^]  Update available: v2.4  (run: youtube --update)
```

To update:

```bash
youtube --update
```

To check your current version:

```bash
youtube --version
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **No audio in downloaded video** | Make sure `ffmpeg` is installed |
| **Only 1080p available** | Update yt-dlp: `pip3 install -U yt-dlp` |
| **Private video won't download** | Use the `-c` flag: `youtube -c <url>` |
| **Keychain prompt appears** | Only happens with `-c`. Without `-c`, cookies are never touched |
| **Cookie extraction fails** | Fully quit Chrome/Brave before retrying with `-c` |
| **fzf not found** | Install manually or use `-b` / `-a` / `-m` presets instead |
| **Script fails on Windows** | Make sure you're running from Git Bash or MSYS2, not PowerShell/cmd |
| **yt-dlp not found after install** | Close and reopen your terminal, then run `source ~/.bashrc` |

## Uninstalling

Remove the `youtube` function from your `~/.zshrc` (or `~/.bashrc`). Look for the block starting with `# YouTube Download (yt-dlp)` and delete everything through the closing `}`.
