#!/bin/bash
getchatstatue() {
openstatue=$(hyprctl clients -j | jq '.[].title')
if  [[ $openstatue =~ (.*)(ChatGPT)(.*) ]]
    then
        echo true
    else
        echo false
fi
}

TOGGL=/tmp/chattoggle
DROPTER='title:(ChatGPT)(.*)'

showchat() {
if [ -f "$TOGGL" ]; then
    #Hide terminal and unpin
	hyprctl --batch "dispatch movewindowpixel 500 0,$DROPTER; dispatch pin $DROPTER; dispatch cyclenext"
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
        touch /tmp/chattoggle && nohup /opt/google/chrome/google-chrome --profile-directory=Default --app-id=jckaldkomadaenmmgladeopgmfbahfjm &
    fi
