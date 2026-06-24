---
name: claude-jukebox
description: 终端音乐播放器控制 — play/pause/next/prev/stop/status
argument-hint: "[play|pause|next|prev|stop|status]"
---

根据用户输入的子命令，执行对应的音乐控制操作。

## 执行方式

直接用 Bash 运行：

```
~/.claude/bin/musicctl.sh $ARGUMENTS
```

## 子命令对照

| 参数 | 动作 |
|------|------|
| play | 开始播放或恢复 |
| pause | 暂停 |
| next | 下一首 |
| prev | 上一首 |
| stop | 停止并退出 |
| status | 查看当前播放状态 |

## 规则

1. 将 $ARGUMENTS 作为参数传给 musicctl.sh
2. 如果没有参数，默认执行 status
3. 向用户简短反馈脚本输出即可
