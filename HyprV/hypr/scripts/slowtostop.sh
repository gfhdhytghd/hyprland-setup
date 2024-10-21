#!/bin/zsh

# 设置初始播放速度
current_speed=0.125
displays=($(xrandr --listmonitors | grep "Monitors:" -A 10 | awk '{print $4}' | grep -v '^$'))
# 每次减少的速度
step=0.0025
gonewbg(){
rm $HOME/Videos/origin/bg.jpg
echo '{ "command": ["screenshot-to-file", "/home/wilf/Videos/bg.jpg"] }' | socat - /tmp/mpv_socket_0 
~/.config/HyprV/hypr/scripts/switchwall-lock.sh
}
gonewbg&
# 循环减少播放速度，直到接近 0
i=0
while (( $(echo "$current_speed > 0" | bc -l) )); do
    # 发送调整速度的命令
    for display in $displays; do
        echo "{\"command\": [\"set_property\", \"speed\", $current_speed]}" | socat - /tmp/mpv_socket_$i
        i=$((i+1))
    done
    # 减少速度
    current_speed="0"$(echo "$current_speed - $step" | bc)""
    echo $current_speed
    # 等待一小段时间
    sleep 0.1
done
sleep 1
# 最后暂停播放
i=0
for display in $displays; do
    echo '{ "command": ["set_property", "pause", true] }' | socat - /tmp/mpv_socket_$i
    i=$((i+1))
done

