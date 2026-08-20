# YouTube Downloader CLI (Interactive)

A smart, interactive command-line tool to download YouTube videos directly from your terminal. Built with `yt-dlp` and `fzf`, this tool automatically bypasses YouTube's bot protection and lets you navigate available video qualities using your arrow keys!

## Features

- **Multi-Platform Auto-Install:** Works on macOS, Linux, and Windows (Git Bash). Automatically installs required dependencies (`yt-dlp` and `fzf`) using your native package manager (`brew`, `apt`, `dnf`, `winget`, `choco`, etc.).
- **Interactive Menu:** Easily select the video quality you want using your arrow keys.
- **Highest Qualities First:** The highest available resolutions (like 1440p and 4K) are automatically sorted to the top of the list.
- **Auto-Stitch Audio:** If you pick a high-res video-only format, the script automatically downloads the best audio and merges them together for you.
- **Bot Bypass:** Uses the YouTube TV client API and browser cookies to completely bypass YouTube's aggressive bot-blocking (so you don't get stuck with just 1080p).
- **Auto-Downloads Directory:** Files are automatically saved straight to your `~/Downloads` folder.

## Installation

You can install this tool directly from your terminal with a single command! Just run:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/your-username/ytd/main/install-ytd.sh)
```

_(Make sure to replace the URL above with the actual raw link from your GitHub repository!)_

### What the installer does:

1. Detects your OS and installs `yt-dlp` and `fzf` if you don't already have them.
2. Figures out if you are using `.zshrc` or `.bashrc`.
3. Adds the smart `youtube` function to your profile.

## Usage

Once installed, just restart your terminal or run `source ~/.zshrc` (or `.bashrc`), and then you can use the command from anywhere:

```bash
youtube <your-youtube-url>
```

**Example:**

```bash
youtube https://youtu.be/kBjrj2UjXCw
```

A menu will appear. Use your **Arrow Keys** to move up and down, and press **Enter** to start downloading!

## Troubleshooting

- **No audio?** You likely skipped the automatic stitching. The script handles it automatically if the format says `video only`. If you see an error about `ffmpeg`, you may need to install `ffmpeg` (`brew install ffmpeg` on Mac).
- **Bot Error / Only 1080p?** If YouTube changes their API again, simply update `yt-dlp` by running `brew upgrade yt-dlp` (or equivalent for your OS).
