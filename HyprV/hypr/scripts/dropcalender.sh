#!/bin/bash
getchatstatue() {
openstatue=$(hyprctl clients -j | jq '.[].class')
if  [[ $openstatue =~ (.*)(chrome-calendar.google.com__calendar_u_0_r-Default)(.*) ]]
    then
        echo true
    else
        echo false
fi
}

TOGGL=/tmp/calendertoggle
DROPTER='chrome-calendar.google.com__calendar_u_0_r-Default'

showchat() {
if [ -f "$TOGGL" ]; then
    #Hide terminal and unpin
	hyprctl --batch "dispatch movewindowpixel 0 -800,$DROPTER;"
	rm $TOGGL
else
    #Show terminal and pin
    hyprctl --batch "dispatch movewindowpixel 0 800,$DROPTER; dispatch pin $DROPTER"
    touch $TOGGL
fi
}

if [[ $(getchatstatue) = true ]]
    then
        showchat
    else
        touch /tmp/calendertoggle && nohup  google-chrome-stable --ignore-gpu-blocklist --enable-zero-copy --enable-features=VaapiVideoDecodeLinuxGL --ozone-platform-hint=auto --ozone-platform=wayland --ozone-platform-hint=auto --enable-features=TouchpadOverscrollHistoryNavigation --enable-wayland-ime --app='https://calendar.google.com/calendar/u/0/r' &
    fi