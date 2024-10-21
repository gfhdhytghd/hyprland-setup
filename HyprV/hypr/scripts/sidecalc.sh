#!/usr/bin/env bash

TOGGLEE=/tmp/sidecalc
DROPTERMMM=org.firebird-emus.firebird-emu
getkittystatue() {
openstatue=$(hyprctl clients -j | jq '.[].class')
if  [[ $openstatue =~ (.*)(org.firebird-emus.firebird-emu)(.*) ]]
    then
        echo true
    else
        echo false
fi
}

showkitty(){
if [ -f "$TOGGLEE" ]; then
    #Hide terminal and unpin
	hyprctl --batch "dispatch movewindowpixel 0 -500,$DROPTERMM; dispatch pin $DROPTERMM; dispatch cyclenext"
	rm $TOGGLEE
else
    #Show terminal and pin
    hyprctl --batch "dispatch movewindowpixel 0 500,$DROPTERMM; dispatch pin $DROPTERMM; dispatch focuswindow $DROPTERMM"
    touch $TOGGLEE
fi
}

if [[ $(getkittystatue) = true ]]
    then
        showkitty
    else
        touch /tmp/sidecalc && nohup  &
    fi


