#!/usr/bin/env bash
set -euo pipefail    # 出错立即退出，调试更方便

TOGGLE=/dev/shm/calendertoggle
LOCK_FILE=/dev/shm/calendertoggle.lock
# Hyprctl 用到的窗口匹配正则，整个用单引号包住即可
APP_REGEX='class:^(chrome-calendar\.google\.com.*Default)$'

# 获取文件锁，避免并发操作
acquire_lock() {
  local timeout=5
  local count=0
  while ! mkdir "$LOCK_FILE" 2>/dev/null; do
    sleep 0.1
    ((count++))
    if [[ $count -gt $((timeout * 10)) ]]; then
      echo "获取锁超时" >&2
      return 1
    fi
  done
  trap 'release_lock' EXIT
}

# 释放文件锁
release_lock() {
  rmdir "$LOCK_FILE" 2>/dev/null || true
}

# 判断窗口是否已存在：有 → 返回 0，无 → 返回 1
getcalendarstatus() {
  hyprctl clients -j 2>/dev/null | \
    jq 'any(.[]; .class | test("chrome-calendar\\.google\\.com.*Default"))' 2>/dev/null | \
    grep -q true 2>/dev/null
}

# 等待窗口状态变化
wait_for_window() {
  local expected_exists=$1
  local max_attempts=30  # 增加等待时间，Chrome启动较慢
  local attempt=0
  
  while [[ $attempt -lt $max_attempts ]]; do
    if [[ $expected_exists == "true" ]]; then
      if getcalendarstatus; then
        return 0
      fi
    else
      if ! getcalendarstatus; then
        return 0
      fi
    fi
    sleep 0.2
    ((attempt++))
  done
  return 1
}

# 安全执行hyprctl命令
safe_hyprctl() {
  local max_retries=3
  local retry=0
  
  while [[ $retry -lt $max_retries ]]; do
    if hyprctl "$@" 2>/dev/null; then
      return 0
    fi
    ((retry++))
    sleep 0.1
  done
  
  echo "hyprctl命令执行失败: $*" >&2
  return 1
}

# 切换 / 隐藏日历窗口
showcalendar() {
  local current_state
  
  # 检查当前窗口是否存在
  if ! getcalendarstatus; then
    echo "日历窗口不存在，无法切换状态" >&2
    return 1
  fi
  
  # 同步检查TOGGLE文件状态
  if [[ -f $TOGGLE ]]; then
    current_state="visible"
  else
    current_state="hidden"
  fi
  
  if [[ $current_state == "visible" ]]; then
    # 已显示 → 隐藏
    if safe_hyprctl dispatch -- movewindowpixel "0 -1000","$APP_REGEX" && \
       safe_hyprctl dispatch pin "$APP_REGEX"; then
      safe_hyprctl dispatch cyclenext
      rm -f "$TOGGLE"
      echo "日历窗口已隐藏"
    else
      echo "隐藏日历窗口失败" >&2
      return 1
    fi
  else
    # 已隐藏 → 显示
    if safe_hyprctl dispatch -- movewindowpixel "0 1000","$APP_REGEX" && \
       safe_hyprctl dispatch pin "$APP_REGEX"; then
      safe_hyprctl dispatch focuswindow "$APP_REGEX"
      touch "$TOGGLE"
      echo "日历窗口已显示"
    else
      echo "显示日历窗口失败" >&2
      return 1
    fi
  fi
}

# 主执行逻辑
main() {
  # 获取文件锁，避免并发执行
  if ! acquire_lock; then
    echo "无法获取锁，可能有其他实例在运行" >&2
    exit 1
  fi
  
  if getcalendarstatus; then
    # 已经有窗口 → 只切换显隐
    showcalendar
  else
    # 没有窗口 → 启动新实例
    echo "启动新的日历实例..."
    
    # 确保启动前状态为隐藏
    rm -f "$TOGGLE"
    
    # 启动新实例
    nohup google-chrome-stable --app="https://calendar.google.com/calendar/u/0/r" \
            --user-data-dir="$HOME/.local/share/chrome-calendar" \
            --ignore-gpu-blocklist --enable-zero-copy \
            --enable-features=VaapiVideoDecodeLinuxGL \
            --ozone-platform-hint=auto --ozone-platform=wayland \
            --enable-features=TouchpadOverscrollHistoryNavigation \
            --enable-wayland-ime \
            >/dev/null 2>&1 &
    local chrome_pid=$!
    
    # 等待窗口出现
    echo "等待日历窗口启动..."
    if wait_for_window "true"; then
      echo "日历实例启动成功"
      # 设置为显示状态
      touch "$TOGGLE"
    else
      echo "等待日历窗口出现超时" >&2
      # 清理失败的进程
      kill $chrome_pid 2>/dev/null || true
      exit 1
    fi
  fi
}

# 执行主逻辑
main "$@"