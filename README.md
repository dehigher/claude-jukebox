# claude-jukebox

A terminal music player skill for [Claude Code](https://claude.ai/code). Control mpv playback with slash commands or natural language, with a real-time statusline showing song progress and synchronized lyrics.

```
♪ 赵雷-成都  ▶ ━━━━━━●──────────────  1:23/5:28
  让我掉下眼泪的 不止昨夜的酒
```

## Features

- **Slash command control** — `/jukebox play|pause|next|prev|stop|status`
- **Natural language** — say "播放音乐", "下一首", "暂停" and Claude understands
- **Real-time statusline** — song name + progress bar + time, refreshes every second
- **Synchronized lyrics** — auto-loads `.lrc` files and displays the current line
- **Lossless playback** — supports FLAC, WAV, APE, DSD, and all mpv-supported formats
- **Shuffle & loop** — plays your music directory in random order, loops indefinitely
- **mpv IPC control** — reliable Unix socket communication, no polling

## Requirements

- macOS or Linux
- [Claude Code](https://claude.ai/code) CLI
- [mpv](https://mpv.io/) (`brew install mpv`)
- Python 3 (macOS ships with it)
- [jq](https://stedolan.github.io/jq/) (optional, for debugging)

## Installation

### Quick Install

```bash
git clone git@github.com:dehigher/claude-jukebox.git
cd claude-jukebox
./install.sh
```

### Manual Install

1. **Copy the control scripts:**

```bash
mkdir -p ~/.claude/bin
cp bin/musicctl.sh ~/.claude/bin/
cp bin/music-status.sh ~/.claude/bin/
chmod +x ~/.claude/bin/musicctl.sh ~/.claude/bin/music-status.sh
```

2. **Install the skill:**

```bash
mkdir -p ~/.claude/skills/claude-jukebox
cp skills/SKILL.md ~/.claude/skills/claude-jukebox/
```

3. **Configure the statusline** — add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/bin/music-status.sh",
    "refreshInterval": 1
  }
}
```

4. **Create your music directory:**

```bash
mkdir -p ~/Music/driving
```

5. **Restart Claude Code** to load the new statusline config.

## Usage

### Slash Commands

| Command | Action |
|---------|--------|
| `/jukebox play` | Start playback (or resume if paused) |
| `/jukebox pause` | Pause playback |
| `/jukebox next` | Skip to next track |
| `/jukebox prev` | Go to previous track |
| `/jukebox stop` | Stop playback and quit mpv |
| `/jukebox status` | Show current track info |

### Natural Language

Just talk to Claude naturally:

- "播放音乐" / "放歌" / "来首歌" → starts playback
- "暂停" / "停一下" → pauses
- "下一首" / "换一首" → next track
- "上一首" → previous track
- "继续播放" / "继续" → resumes
- "停止音乐" / "关掉音乐" → stops
- "现在放什么" / "在听什么" → shows status

### CLI Usage (outside Claude Code)

The control script works standalone in any terminal:

```bash
~/.claude/bin/musicctl.sh play
~/.claude/bin/musicctl.sh next
~/.claude/bin/musicctl.sh status
# Output: ▶ 赵雷-成都.wav [1:23 / 5:28]
```

## Music Directory

By default, claude-jukebox plays from `~/Music/driving/`. Drop your music files there:

```
~/Music/driving/
├── 赵雷-成都.flac
├── 赵雷-成都.lrc        ← optional lyrics
├── 宋冬野-斑马斑马.wav
├── 宋冬野-斑马斑马.lrc
├── 许巍-蓝莲花.flac
└── ...
```

### Supported Formats

Any format mpv supports: **FLAC, WAV, APE, DSD, AAC, MP3, OGG, OPUS, WMA, M4A**, etc.

## Lyrics

Place a `.lrc` file with the same name as the audio file in the same directory. The statusline will automatically display synchronized lyrics.

**Example** `赵雷-成都.lrc`:

```
[00:18.00]让我掉下眼泪的 不止昨夜的酒
[00:25.00]让我依依不舍的 不止你的温柔
[00:32.00]余路还要走多久 你攥着我的手
...
```

LRC files can be downloaded from music platforms (NetEase Cloud Music exports them with downloads) or found by searching "{song name} lrc".

## Statusline

When music is playing, the Claude Code statusline shows:

```
♪ 赵雷-成都  ▶ ━━━━━━━━●───────────  2:45/5:28
  余路还要走多久 你攥着我的手
```

- Line 1: Song title + play/pause icon + progress bar + timestamp
- Line 2: Current lyric line (dimmed, only shown if .lrc file exists)
- When nothing is playing, the statusline is hidden

The statusline refreshes every 1 second via `refreshInterval` in settings.

## How It Works

```
┌─────────────┐     IPC Socket      ┌─────────┐
│ musicctl.sh │ ──────────────────── │   mpv   │
└─────────────┘   /tmp/mpv-music.sock└─────────┘
       ▲                                  ▲
       │                                  │
  Claude Code                    ~/Music/driving/*
  (skill trigger)                (audio files)

┌──────────────────┐   reads socket    ┌─────────┐
│ music-status.sh  │ ─────────────────→│   mpv   │
│  (statusline)    │   + parses .lrc   └─────────┘
└──────────────────┘
```

- **mpv** runs in the background with `--input-ipc-server=/tmp/mpv-music.sock`
- **musicctl.sh** sends JSON commands to mpv via the Unix socket (using Python3 socket)
- **music-status.sh** queries mpv state every second and parses the matching `.lrc` file
- **SKILL.md** tells Claude how to map user intent to musicctl.sh commands

## Configuration

### Change Music Directory

Edit `MUSIC_DIR` in both `bin/musicctl.sh` and `bin/music-status.sh`:

```bash
MUSIC_DIR="$HOME/Music/driving"  # change to your preferred path
```

### Disable Shuffle

Edit `bin/musicctl.sh`, find the `mpv` launch line and remove `--shuffle`:

```bash
mpv --no-video --loop-playlist \
    --input-ipc-server="$SOCKET" \
    "$MUSIC_DIR"/* &>/dev/null &
```

### Statusline Refresh Rate

In `~/.claude/settings.json`, adjust `refreshInterval` (minimum 1 second):

```json
"refreshInterval": 2
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "未在播放" but mpv is running | Socket mismatch — run `killall mpv` and restart with `/jukebox play` |
| No lyrics in statusline | Ensure `.lrc` filename matches audio filename exactly (minus extension) |
| Statusline not showing | Restart Claude Code after adding statusLine to settings.json |
| mpv not found | `brew install mpv` (macOS) or `apt install mpv` (Linux) |
| Permission denied | `chmod +x ~/.claude/bin/musicctl.sh ~/.claude/bin/music-status.sh` |

## Uninstall

```bash
rm -rf ~/.claude/skills/claude-jukebox
rm ~/.claude/bin/musicctl.sh ~/.claude/bin/music-status.sh
# Remove "statusLine" section from ~/.claude/settings.json
```

## License

MIT
