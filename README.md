# Hyprland-setup

This is the Hyprland install script.(Not Official). 

Fork from https://github.com/SolDoesTech/HyprV3

## Note of using
The default keybind will be in ~/.config/HyprV/hypr/hyprland-bind.conf.
PLEASE READ IT.
If you need to change the monitor setting, go to ~/.config/HyprV/hypr/hyprland-monitor.conf.

I recommand you to install hycov, I like this plugin very much, but for compatibility reasons I won't put it in the script for now.
NOTE that you have to re-install this plugin every time after upgrade or reinstall hyprland, otherwise it may cause hyprland crush.

repo at:
```
https://github.com/DreamMaoMao/hycov
```

## Install using script

```
git clone https://github.com/gfhdhytghd/hyprland-setup.git
cd hyprland-setup
./set-hypr
```

Default behavior:
- Interactive mode.
- Installs package group `core`.
- Risky system changes require confirmation.

Useful examples:

```bash
# Install core + theme packages, deploy config, and enable bluetooth.
./set-hypr --groups core,theme --apply-config --enable-service bluetooth

# Include NVIDIA setup and SDDM theme.
./set-hypr --with-nvidia --apply-sddm-theme --enable-service sddm

# Non-interactive run (risky actions must be explicit flags).
./set-hypr --non-interactive --yes \
  --groups core,theme \
  --apply-config \
  --enable-service bluetooth,sddm \
  --with-nvidia \
  --disable-wifi-powersave
```

Show all options:

```bash
./set-hypr --help
```

Logs are written to `install.log` by default (customizable with `--log-file`).

## Deafult key bind

### Miscellaneous

ALT+SPACE        open app menu

SUPER+Q          open the terminal

SUPER+F4         close the active window

SUPER+L          Lock the screen

SUPER+M          show the logout window

SUPER+SHIFT+M    Force exit hyprland

SUPER+F          start vscode

SUPER+E          Show file brosewer

SUPER+V          toggle floating

SUPER+P          deindle

SUPER+J          togglesplit,rotate the arrangement

SUPER+O          expand window

SUPER+SHIFT+O    FULL screen

SUPER+S          screenshot

SUPER+I          start vivaldi

SUPER+B          toggle low battery mod

SUPER+R          toggle start/stop v2raya

SUPER+SHIFT+R    stop v2raya

### Move focus with SUPER + arrow keys

SUPER+up

SUPER+down

SUPER+left

SUPER+right

### Switch workspaces with SUPER + [0-9]
### Scroll through existing workspaces with SUPER + scroll
### Move/resize windows with mainMod + LMB/RMB and dragging

SUPER+LMB         move windows
SUPER+RMB         resize windows
