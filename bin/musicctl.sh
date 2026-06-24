#!/bin/bash
# musicctl.sh - mpv music controller via IPC socket
# Part of claude-jukebox

MUSIC_DIR="$HOME/Music/driving"
SOCKET="/tmp/mpv-music.sock"

mpv_cmd() {
    python3 -c "
import socket, json, sys
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(0.5)
    s.connect('$SOCKET')
    s.sendall((sys.argv[1] + '\n').encode())
    data = b''
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        data += chunk
        if b'\n' in data:
            break
    resp = json.loads(data.split(b'\n')[0])
    if 'data' in resp:
        print(resp['data'])
    elif 'error' in resp and resp['error'] != 'success':
        print(resp['error'], file=sys.stderr)
    s.close()
except Exception as e:
    print(str(e), file=sys.stderr)
    sys.exit(1)
" "$1" 2>/dev/null
}

mpv_running() {
    [ -S "$SOCKET" ] && mpv_cmd '{"command":["get_property","pid"]}' >/dev/null 2>&1
}

case "${1:-status}" in
    play)
        if mpv_running; then
            mpv_cmd '{"command":["set_property","pause",false]}'
            echo "▶ 继续播放"
        else
            rm -f "$SOCKET"
            mpv --no-video --shuffle --loop-playlist \
                --input-ipc-server="$SOCKET" \
                "$MUSIC_DIR"/* &>/dev/null &
            disown
            sleep 0.8
            if [ -S "$SOCKET" ]; then
                echo "▶ 开始播放 ~/Music/driving/"
            else
                echo "✗ 启动失败，请检查 ~/Music/driving/ 目录是否有音乐文件"
                exit 1
            fi
        fi
        ;;
    pause)
        if mpv_running; then
            mpv_cmd '{"command":["set_property","pause",true]}'
            echo "⏸ 已暂停"
        else
            echo "未在播放"
        fi
        ;;
    toggle)
        if mpv_running; then
            mpv_cmd '{"command":["cycle","pause"]}'
        else
            echo "未在播放"
        fi
        ;;
    next)
        if mpv_running; then
            mpv_cmd '{"command":["playlist-next"]}'
            sleep 0.3
            title=$(mpv_cmd '{"command":["get_property","media-title"]}')
            echo "⏭ 下一首: $title"
        else
            echo "未在播放"
        fi
        ;;
    prev)
        if mpv_running; then
            mpv_cmd '{"command":["playlist-prev"]}'
            sleep 0.3
            title=$(mpv_cmd '{"command":["get_property","media-title"]}')
            echo "⏮ 上一首: $title"
        else
            echo "未在播放"
        fi
        ;;
    stop)
        if mpv_running; then
            mpv_cmd '{"command":["quit"]}'
            echo "⏹ 已停止"
        else
            echo "未在播放"
        fi
        ;;
    status)
        if ! mpv_running; then
            echo "未在播放"
            exit 0
        fi
        title=$(mpv_cmd '{"command":["get_property","media-title"]}')
        paused=$(mpv_cmd '{"command":["get_property","pause"]}')
        pos=$(mpv_cmd '{"command":["get_property","time-pos"]}')
        dur=$(mpv_cmd '{"command":["get_property","duration"]}')
        pos_fmt=$(printf "%d:%02d" $((${pos%.*}/60)) $((${pos%.*}%60)) 2>/dev/null)
        dur_fmt=$(printf "%d:%02d" $((${dur%.*}/60)) $((${dur%.*}%60)) 2>/dev/null)
        if [ "$paused" = "True" ] || [ "$paused" = "true" ]; then
            state="⏸"
        else
            state="▶"
        fi
        echo "$state $title [$pos_fmt / $dur_fmt]"
        ;;
    *)
        echo "用法: musicctl.sh {play|pause|toggle|next|prev|stop|status}"
        exit 1
        ;;
esac
