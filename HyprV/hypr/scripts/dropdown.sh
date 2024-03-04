#!/usr/bin/env bash

TOGGLE=/tmp/droptoggle
DROPTERM=kitty-dropdown
getkittystatue() {
openstatue=$(hyprctl clients -j | jq '.[].class')
if  [[ $openstatue =~ (.*)(kitty-dropdown)(.*) ]]
    then
        echo true
    else
        echo false
fi
}

showkitty(){
if [ -f "$TOGGLE" ]; then
    #Hide terminal and unpin
	hyprctl --batch "dispatch movewindowpixel 0 -500,$DROPTERM; dispatch pin $DROPTERM; dispatch cyclenext"
	rm $TOGGLE
else
    #Show terminal and pin
    hyprctl --batch "dispatch movewindowpixel 0 500,$DROPTERM; dispatch pin $DROPTERM; dispatch focuswindow $DROPTERM"
    touch $TOGGLE
fi
}

if [[ $(getkittystatue) = true ]]
    then
        showkitty
    else
        touch /tmp/droptoggle && nohup kitty --class=kitty-dropdown &
    fi


