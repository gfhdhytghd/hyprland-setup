#!/bin/zsh
# 继续播放
displays=($(xrandr --listmonitors | grep "Monitors:" -A 10 | awk '{print $4}' | grep -v '^$'))
i=0
for display in $displays; do
    echo $i
    echo '{ "command": ["set_property", "pause", false] }' | socat - /tmp/mpv_socket_$i 
    i=$((i+1))
done
# 设置初始播放速度
current_speed=0.005

# 每次增加的速度
step=0.005
# 循环增加播放速度
while (( $(echo "$current_speed < 0.125" | bc -l) )); do
    # 发送调整速度的命令
    i=0
    for display in $displays; do
        echo "{\"command\": [\"set_property\", \"speed\", $current_speed]}" | socat - /tmp/mpv_socket_$i
        i=$((i+1))
    done
    # 减少速度
    current_speed="0"$(echo "$current_speed + $step" | bc)""
    echo $current_speed
    # 等待一小段时间
    sleep 0.1
done

