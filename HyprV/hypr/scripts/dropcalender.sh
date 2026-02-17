#!/usr/bin/env bash
set -euo pipefail    # 出错立即退出，调试更方便

TOGGLE=/dev/shm/calendertoggle
LOCK_FILE=/dev/shm/calendertoggle.lock
PREV_FOCUS=/dev/shm/calendertoggle.prev_focus
PREV_WS=/dev/shm/calendertoggle.prev_ws
HIDDEN_WS='special:calendar_hidden'
ANIM_OFFSET=1000
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

# 获取日历窗口地址
get_calendar_address() {
  hyprctl clients -j 2>/dev/null | \
    jq -r 'first(.[] | select(.class | test("chrome-calendar\\.google\\.com.*Default")) | .address) // empty' 2>/dev/null
}

# 判断是否在隐藏专用工作区
is_hidden_in_special() {
  local addr
  addr="$(get_calendar_address)"
  [[ -n "$addr" ]] || return 1

  hyprctl clients -j 2>/dev/null | \
    jq -e --arg addr "$addr" --arg ws "$HIDDEN_WS" \
      'any(.[]; .address == $addr and .workspace.name == $ws)' >/dev/null 2>&1
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

# 单次垂直位移动画（高效版）
animate_vertical() {
  local dy=$1
  local addr=$2
  safe_hyprctl dispatch -- movewindowpixel "0 ${dy}","address:${addr}" || true
}

# 记录当前焦点窗口，便于收起时恢复
save_prev_focus() {
  local current_focus
  local current_ws
  current_focus="$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' 2>/dev/null)"
  current_ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' 2>/dev/null)"
  if [[ -n "$current_focus" ]]; then
    printf '%s\n' "$current_focus" > "$PREV_FOCUS"
  else
    rm -f "$PREV_FOCUS"
  fi
  if [[ -n "$current_ws" ]]; then
    printf '%s\n' "$current_ws" > "$PREV_WS"
  else
    rm -f "$PREV_WS"
  fi
}

# 收起后恢复到展开前的焦点窗口
restore_prev_focus() {
  local prev_focus
  local prev_ws
  local current_ws

  if [[ ! -f "$PREV_FOCUS" ]]; then
    rm -f "$PREV_WS"
    return 0
  fi

  prev_focus="$(cat "$PREV_FOCUS")"
  if [[ -z "$prev_focus" ]]; then
    rm -f "$PREV_FOCUS"
    rm -f "$PREV_WS"
    return 0
  fi

  if [[ -f "$PREV_WS" ]]; then
    prev_ws="$(cat "$PREV_WS")"
    current_ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' 2>/dev/null)"
    if [[ -n "$prev_ws" && -n "$current_ws" && "$prev_ws" != "$current_ws" ]]; then
      rm -f "$PREV_FOCUS" "$PREV_WS"
      return 0
    fi
  fi

  if hyprctl clients -j 2>/dev/null | jq -e --arg addr "$prev_focus" 'any(.[]; .address == $addr)' >/dev/null 2>&1; then
    safe_hyprctl dispatch focuswindow "address:$prev_focus" || true
  fi

  rm -f "$PREV_FOCUS" "$PREV_WS"
}

# 切换 / 隐藏日历窗口
showcalendar() {
  local addr
  local current_ws
  
  # 检查当前窗口是否存在
  if ! getcalendarstatus; then
    echo "日历窗口不存在，无法切换状态" >&2
    return 1
  fi

  addr="$(get_calendar_address)"
  if [[ -z "$addr" ]]; then
    echo "无法获取日历窗口地址" >&2
    return 1
  fi

  if is_hidden_in_special; then
    # 已隐藏 → 显示到当前工作区，再下移回可见位置
    save_prev_focus
    current_ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' 2>/dev/null)"
    if [[ -z "$current_ws" ]]; then
      echo "无法获取当前工作区" >&2
      return 1
    fi

    if safe_hyprctl dispatch movetoworkspacesilent "${current_ws},address:${addr}" && \
       safe_hyprctl dispatch focuswindow "address:${addr}"; then
      animate_vertical "${ANIM_OFFSET}" "$addr"
      touch "$TOGGLE"
      echo "日历窗口已显示"
    else
      echo "显示日历窗口失败" >&2
      return 1
    fi
  else
    # 已显示 → 先上移，再隐藏到专用 special workspace，并恢复之前焦点
    animate_vertical "$((-ANIM_OFFSET))" "$addr"
    if safe_hyprctl dispatch movetoworkspacesilent "${HIDDEN_WS},address:${addr}"; then
      rm -f "$TOGGLE"
      restore_prev_focus
      echo "日历窗口已隐藏"
    else
      echo "隐藏日历窗口失败" >&2
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
    save_prev_focus
    
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
      # 新建窗口已经在显示位置，不做下移动画，只标记为可见
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
