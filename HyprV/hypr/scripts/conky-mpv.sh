#!/bin/bash
sleep 7
# 获取所有显示器名称
displays=($(xrandr --listmonitors | grep "Monitors:" -A 10 | awk '{print $4}' | grep -v '^$'))
# 遍历每个显示器并启动 Conky 实例
i=0
for display in $displays; do
    # 启动 mpv 实例并指定其 DISPLAY 环境变量
    hyprctl keyword windowrule "monitor $i, title:^(MPV$i)$" 
    MONITOR=$display mpv --hwdec=auto --panscan=1.0 -speed=0.125 --title="MPV$i" -input-ipc-server=/tmp/mpv_socket_$i ~/Videos/bg.mov  &
    
    # 获取 PID 并保存
    pid=$!
    echo "Started mpv on $display with PID $pid"
    
    # 增加一个唯一标识符，确保每个实例独立
    i=$((i+1))
done
echo '{ "command": ["set_property", "pause", true] }' | socat - /tmp/mpv_socket
echo '{ "command": ["screenshot-to-file", "/home/wilf/Videos/bg.jpg"] }' | socat - /tmp/mpv_socket
~/.config/HyprV/hypr/scripts/switchwall-lock.sh
