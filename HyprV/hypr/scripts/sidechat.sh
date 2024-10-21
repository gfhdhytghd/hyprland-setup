#!/bin/bash
getchatstatue() {
openstatue=$(hyprctl clients -j | jq '.[].class')
if  [[ $openstatue =~ (.*)(chrome-chat.openai.com__-Default)(.*) ]]
    then
        echo true
    else
        echo false
fi
}

TOGGL=/tmp/chattoggle
DROPTER='chrome-chat.openai.com__-Default'

showchat() {
if [ -f "$TOGGL" ]; then
    #Hide terminal and unpin
	hyprctl --batch "dispatch movewindowpixel 500 0,$DROPTER;"
	rm $TOGGL
else
    #Show terminal and pin
    hyprctl --batch "dispatch movewindowpixel -500 0,$DROPTER; dispatch pin $DROPTER"
    touch $TOGGL
fi
}

if [[ $(getchatstatue) = true ]]
    then
        showchat
    else
        touch /tmp/chattoggle && nohup  chromium --ignore-gpu-blocklist --enable-zero-copy --enable-features=VaapiVideoDecodeLinuxGL --ozone-platform-hint=auto --ozone-platform=wayland --ozone-platform-hint=auto --enable-features=TouchpadOverscrollHistoryNavigation --enable-wayland-ime --app='https://chat.openai.com' &
    fi