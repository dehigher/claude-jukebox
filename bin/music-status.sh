#!/bin/bash
# music-status.sh - Claude Code statusline script for claude-jukebox
# Shows: song name + progress bar + current lyric

SOCKET="/tmp/mpv-music.sock"
MUSIC_DIR="$HOME/Music/driving"

# Quick exit if mpv not running
[ -S "$SOCKET" ] || exit 0

# Query mpv properties via python
info=$(python3 -c "
import socket, json

def query(s, prop):
    cmd = json.dumps({'command': ['get_property', prop]}) + '\n'
    s.sendall(cmd.encode())
    data = b''
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        data += chunk
        if b'\n' in data:
            break
    try:
        return json.loads(data.split(b'\n')[0]).get('data', '')
    except:
        return ''

try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(0.3)
    s.connect('$SOCKET')
    title = query(s, 'media-title')
    pos = query(s, 'time-pos')
    dur = query(s, 'duration')
    paused = query(s, 'pause')
    filename = query(s, 'filename')
    s.close()
    print(f'{title}\t{pos}\t{dur}\t{paused}\t{filename}')
except:
    pass
" 2>/dev/null)

[ -z "$info" ] && exit 0

IFS=$'\t' read -r title pos dur paused filename <<< "$info"
[ -z "$title" ] && exit 0
[ -z "$dur" ] && exit 0

# Integer positions
pos_int=${pos%.*}
dur_int=${dur%.*}
[ -z "$dur_int" ] || [ "$dur_int" = "0" ] && exit 0

# Format time
pos_fmt=$(printf "%d:%02d" $((pos_int/60)) $((pos_int%60)))
dur_fmt=$(printf "%d:%02d" $((dur_int/60)) $((dur_int%60)))

# Progress bar (20 chars)
pct=$((pos_int * 20 / dur_int))
bar=""
for ((i=0; i<20; i++)); do
    if [ $i -eq $pct ]; then
        bar="${bar}●"
    elif [ $i -lt $pct ]; then
        bar="${bar}━"
    else
        bar="${bar}─"
    fi
done

# State icon
if [ "$paused" = "True" ] || [ "$paused" = "true" ]; then
    icon="⏸"
else
    icon="▶"
fi

# Find LRC file and get current lyric
stem="${filename%.*}"
lrc_file="$MUSIC_DIR/${stem}.lrc"
lyric=""
if [ -f "$lrc_file" ]; then
    lyric=$(python3 -c "
import re
pos = float('${pos}')
best_time = -1
best_line = ''
with open('$lrc_file', encoding='utf-8') as f:
    for line in f:
        m = re.match(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)', line)
        if m:
            t = int(m.group(1)) * 60 + float(m.group(2))
            text = m.group(3).strip()
            if t <= pos and t > best_time and text:
                best_time = t
                best_line = text
print(best_line)
" 2>/dev/null)
fi

# Output line 1: song + progress
echo -e "\033[36m♪\033[0m ${title}  ${icon} ${bar}  ${pos_fmt}/${dur_fmt}"

# Output line 2: lyric (if available)
if [ -n "$lyric" ]; then
    echo -e "\033[2m  ${lyric}\033[0m"
fi
