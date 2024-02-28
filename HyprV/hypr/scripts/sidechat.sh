#!/bin/bash
getchatstatue() {
openstatue=$(hyprctl clients -j | jq '.[].class')
if  [[ $openstatue =~ (.*)(copilot)(.*) ]]
    then
        echo true
    else
        echo false
fi
}

TOGGL=/tmp/chattoggle
DROPTER=copilot

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
        touch /tmp/chattoggle && nohup  google-chrome-stable --app='https://chat.openai.com' --class='copilot' &
    fi
