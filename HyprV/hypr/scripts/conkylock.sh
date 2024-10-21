#!/bin/bash

# 获取所有显示器名称
displays=$(xrandr --listmonitors | grep "Monitors:" -A 10 | awk '{print $4}' | grep -v '^$')

# 遍历每个显示器并启动 Conky 实例
i=0
for display in $displays; do
    # 启动 Conky 实例并指定其 DISPLAY 环境变量
    MONITOR=$display conky -c ~/.config/conky/conky.conf -d &
    
    # 获取 PID 并保存
    pid=$!
    echo "Started conky on $display with PID $pid"
    
    # 增加一个唯一标识符，确保每个实例独立
    i=$((i+1))
done
