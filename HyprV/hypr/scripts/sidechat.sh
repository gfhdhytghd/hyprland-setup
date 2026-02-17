#!/usr/bin/env bash
set -euo pipefail    # 出错立即退出，调试更方便

TOGGLE=/dev/shm/sidechat
PREV_FOCUS=/dev/shm/sidechat.prev_focus
PREV_WS=/dev/shm/sidechat.prev_ws
HIDDEN_WS='special:sidechat_hidden'
ANIM_OFFSET_X=500
# Hyprctl 用到的窗口匹配正则，整个用单引号包住即可
APP_REGEX='class:^(chrome-chatgpt\.com.*Default)$'

# 判断窗口是否已存在：有 → 返回 0，无 → 返回 1
getkittystatus() {
  hyprctl clients -j 2>/dev/null | \
    jq 'any(.[]; .class | test("chrome-chatgpt\\.com.*Default"))' 2>/dev/null | \
    grep -q true 2>/dev/null
}

# 获取 sidechat 窗口地址
get_sidechat_address() {
  hyprctl clients -j 2>/dev/null | \
    jq -r 'first(.[] | select(.class | test("chrome-chatgpt\\.com.*Default")) | .address) // empty' 2>/dev/null
}

# 判断是否在隐藏专用工作区
is_hidden_in_special() {
  local addr
  addr="$(get_sidechat_address)"
  [[ -n "$addr" ]] || return 1

  hyprctl clients -j 2>/dev/null | \
    jq -e --arg addr "$addr" --arg ws "$HIDDEN_WS" \
      'any(.[]; .address == $addr and .workspace.name == $ws)' >/dev/null 2>&1
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

# 单次水平位移动画（高效版）
animate_horizontal() {
  local dx=$1
  local addr=$2
  safe_hyprctl dispatch -- movewindowpixel "${dx} 0","address:${addr}" || true
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

  if ! getkittystatus; then
    echo "聊天窗口不存在，无法切换状态" >&2
    return 1
  fi

  addr="$(get_sidechat_address)"
  if [[ -z "$addr" ]]; then
    echo "无法获取聊天窗口地址" >&2
    return 1
  fi

  if is_hidden_in_special; then
    # 已隐藏 → 显示到当前工作区，然后左移回可见区域
    save_prev_focus
    current_ws="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty' 2>/dev/null)"
    if [[ -z "$current_ws" ]]; then
      echo "无法获取当前工作区" >&2
      return 1
    fi

    if safe_hyprctl dispatch movetoworkspacesilent "${current_ws},address:${addr}" && \
       safe_hyprctl dispatch focuswindow "address:${addr}"; then
      animate_horizontal "$((-ANIM_OFFSET_X))" "$addr"
      touch "$TOGGLE"
      echo "聊天窗口已显示"
    else
      echo "显示聊天窗口失败" >&2
      return 1
    fi
  else
    # 已显示 → 右移后隐藏到专用 special workspace
    animate_horizontal "${ANIM_OFFSET_X}" "$addr"
    if safe_hyprctl dispatch movetoworkspacesilent "${HIDDEN_WS},address:${addr}"; then
      rm -f "$TOGGLE"
      restore_prev_focus
      echo "聊天窗口已隐藏"
    else
      echo "隐藏聊天窗口失败" >&2
      return 1
    fi
  fi
}

if getkittystatus; then
  # 已经有窗口 → 只切换显隐
  showchat
else
  # 没有 → 启动新实例
  save_prev_focus
  rm -f "$TOGGLE"
  touch "$TOGGLE"
  # 建议加 --user-data-dir 区分配置，避免多次启动 profile 冲突
  nohup chromium --app="https://chatgpt.com" --user-data-dir="$HOME/.local/share/chrome-chatgpt" \
        >/dev/null 2>&1 &
fi
