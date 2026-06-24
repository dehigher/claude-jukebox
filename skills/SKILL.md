---
name: claude-jukebox
description: 终端音乐播放器 — 通过 /jukebox 或自然语言控制 mpv 播放 ~/Music/driving/ 目录下的音乐，支持播放/暂停/切歌，配合状态栏显示进度和歌词
version: 1.0.0
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: productivity
  use-case: terminal-music-player
---

# claude-jukebox

终端无损音乐播放器，通过 mpv + IPC Socket 实现播放控制，配合 Claude Code 状态栏实时显示歌曲进度和歌词。

## 触发条件

- 斜杠命令: `/jukebox [play|pause|next|prev|stop|status]`
- 自然语言: "播放音乐", "放歌", "来首歌", "下一首", "上一首", "暂停", "继续播放", "停止音乐", "现在放什么歌"

## 执行方式

调用 Bash 执行控制脚本 `~/.claude/bin/musicctl.sh`:

| 用户意图 | 执行命令 |
|----------|----------|
| 播放/恢复 | `~/.claude/bin/musicctl.sh play` |
| 暂停 | `~/.claude/bin/musicctl.sh pause` |
| 下一首 | `~/.claude/bin/musicctl.sh next` |
| 上一首 | `~/.claude/bin/musicctl.sh prev` |
| 查看状态 | `~/.claude/bin/musicctl.sh status` |
| 停止退出 | `~/.claude/bin/musicctl.sh stop` |

## 行为规则

1. 如果用户说"播放音乐"/"放歌"/"来首歌"/"继续" → 执行 `play`
2. 如果用户说"暂停"/"停一下" → 执行 `pause`
3. 如果用户说"下一首"/"换一首"/"next" → 执行 `next`
4. 如果用户说"上一首"/"prev" → 执行 `prev`
5. 如果用户说"停止音乐"/"关掉音乐" → 执行 `stop`
6. 如果用户说"现在放什么"/"在听什么" → 执行 `status`
7. 执行后向用户简短反馈脚本输出即可

## 播放目录

固定为 `~/Music/driving/`，支持 FLAC/WAV/APE/MP3 等所有 mpv 支持的格式。

## 歌词

如果音频文件同目录下有同名 `.lrc` 文件，状态栏会自动显示当前歌词。

## 依赖

- mpv (`brew install mpv`)
- python3 (macOS 自带)
