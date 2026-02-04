#!/usr/bin/env bash
set -euo pipefail    # 出错立即退出，调试更方便

TOGGLE=/dev/shm/sidechat
# Hyprctl 用到的窗口匹配正则，整个用单引号包住即可
APP_REGEX='class:^(chrome-chatgpt\.com.*Default)$'

# 判断窗口是否已存在：有 → 返回 0，无 → 返回 1
getkittystatus() {
  hyprctl clients -j | \
    jq 'any(.[]; .class | test("chrome-chatgpt\\.com.*Default"))' | \
    grep -q true
}

# 切换 / 隐藏侧边聊天窗口
showchat() {
  if [[ -f $TOGGLE ]]; then
    # 已在右侧 → 折叠并取消 pin
    hyprctl dispatch -- movewindowpixel "500 0","$APP_REGEX"
    hyprctl dispatch pin "$APP_REGEX"
    hyprctl dispatch cyclenext
    rm -f "$TOGGLE"
  else
    # 不在右侧 → 展开并 pin
    hyprctl dispatch -- movewindowpixel "-500 0","$APP_REGEX"
    hyprctl dispatch pin "$APP_REGEX"
    hyprctl dispatch focuswindow "$APP_REGEX"
    touch "$TOGGLE"
  fi
}

if getkittystatus; then
  # 已经有窗口 → 只切换显隐
  showchat
else
  # 没有 → 启动新实例
  touch "$TOGGLE"
  # 建议加 --user-data-dir 区分配置，避免多次启动 profile 冲突
  nohup chromium --app="https://chatgpt.com" --user-data-dir="$HOME/.local/share/chrome-chatgpt" \
        >/dev/null 2>&1 &
fi
