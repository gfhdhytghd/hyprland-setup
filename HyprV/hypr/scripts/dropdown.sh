TOGGLE=/dev/shm/dropdown
LOCK_FILE=/dev/shm/dropdown.lock
PREV_FOCUS=/dev/shm/dropdown.prev_focus
PREV_WS=/dev/shm/dropdown.prev_ws
HIDDEN_WS='special:dropdown_hidden'
ANIM_OFFSET=420
# Hyprctl 用到的窗口匹配正则，整个用单引号包住即可
APP_REGEX='class:^(alacritty-dropdown)$'

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
getalacrittystatus() {
  hyprctl clients -j 2>/dev/null | \
    jq 'any(.[]; .class | test("alacritty-dropdown"))' 2>/dev/null | \
    grep -q true 2>/dev/null
}

# 获取 dropdown 窗口地址
get_dropdown_address() {
  hyprctl clients -j 2>/dev/null | \
    jq -r 'first(.[] | select(.class | test("alacritty-dropdown")) | .address) // empty' 2>/dev/null
}

# 判断是否在隐藏专用工作区
is_hidden_in_special() {
  local addr
  addr="$(get_dropdown_address)"
  [[ -n "$addr" ]] || return 1

  hyprctl clients -j 2>/dev/null | \
    jq -e --arg addr "$addr" --arg ws "$HIDDEN_WS" \
      'any(.[]; .address == $addr and .workspace.name == $ws)' >/dev/null 2>&1
}

# 等待窗口状态变化
wait_for_window() {
  local expected_exists=$1
  local max_attempts=20
  local attempt=0
  
  while [[ $attempt -lt $max_attempts ]]; do
    if [[ $expected_exists == "true" ]]; then
      if getalacrittystatus; then
        return 0
      fi
    else
      if ! getalacrittystatus; then
        return 0
      fi
    fi
    sleep 0.1
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

# 单次位移动画（等效于 steps=1 的分帧实现）
animate_vertical() {
  local total=$1
  local addr=$2
  safe_hyprctl dispatch -- movewindowpixel "0 ${total}","address:${addr}" || true
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

# 切换 / 隐藏侧边聊天窗口
showchat() {
  local addr
  local current_ws
  
  # 检查当前窗口是否存在
  if ! getalacrittystatus; then
    echo "窗口不存在，无法切换状态" >&2
    return 1
  fi
  
  addr="$(get_dropdown_address)"
  if [[ -z "$addr" ]]; then
    echo "无法获取窗口地址" >&2
    return 1
  fi

  if is_hidden_in_special; then
    # 已隐藏 → 显示到当前工作区
    save_prev_focus
    current_ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' 2>/dev/null)"
    if [[ -z "$current_ws" ]]; then
      echo "无法获取当前工作区" >&2
      return 1
    fi

    # 显示顺序：先取消隐藏，再下移回到可见位置
    if safe_hyprctl dispatch movetoworkspacesilent "${current_ws},address:${addr}" && \
       safe_hyprctl dispatch focuswindow "address:${addr}"; then
      animate_vertical "${ANIM_OFFSET}" "$addr"
      touch "$TOGGLE"
      echo "窗口已显示"
    else
      echo "显示窗口失败" >&2
      return 1
    fi
  else
    # 已显示 → 隐藏到专用 special workspace
    animate_vertical "$((-ANIM_OFFSET))" "$addr"
    if safe_hyprctl dispatch movetoworkspacesilent "${HIDDEN_WS},address:${addr}"; then
      rm -f "$TOGGLE"
      restore_prev_focus
      echo "窗口已隐藏"
    else
      echo "隐藏窗口失败" >&2
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
  
  if getalacrittystatus; then
    # 已经有窗口 → 只切换显隐
    showchat
  else
    # 没有窗口 → 启动新实例
    echo "启动新的Alacritty实例..."
    save_prev_focus
    
    # 确保启动前状态为隐藏
    rm -f "$TOGGLE"
    
    # 启动新实例
    # 在 Wayland 上 --class 的第二个参数会作为 app_id；在 X11 上作为通用类名
    nohup alacritty --class alacritty-dropdown,alacritty-dropdown >/dev/null 2>&1 &
    local alacritty_pid=$!
    
    # 等待窗口出现
    if wait_for_window "true"; then
      echo "Alacritty实例启动成功"
      # 新建窗口已经在显示位置，不做下移动画，只标记为可见
      touch "$TOGGLE"
    else
      echo "等待窗口出现超时" >&2
      # 清理失败的进程
      kill $alacritty_pid 2>/dev/null || true
      exit 1
    fi
  fi
}

# 执行主逻辑
main "$@"
