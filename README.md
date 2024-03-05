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
sudo chmod +x set-hypr
./set-hypr
```

## Manual installation

collection of dot config files for hyprland with a simple install script for a fresh Arch linux with yay

You can grab the config files and install packages by hand with this command

Do this ONLY if you need Nvidia support (do this first)
```
yay -S linux-headers nvidia-dkms qt5-wayland qt5ct libva libva-nvidia-driver-git

Add modules: nvidia nvidia_modeset nvidia_uvm nvidia_drm to /etc/mkinitcpio.conf

Generate new image: sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img

Add/create the following: options nvidia-drm modeset=1 in /etc/modprobe.d/nvidia.conf

reboot!
```

Now install the below for Hyprland

```
yay -S hyprland kitty jq mako waybar-hyprland swww swaylock-effects \
wofi wlogout xdg-desktop-portal-hyprland swappy grim slurp thunar \
polkit-gnome python-requests pamixer pavucontrol brightnessctl bluez \
bluez-utils blueman network-manager-applet gvfs thunar-archive-plugin \
file-roller btop pacman-contrib starship ttf-jetbrains-mono-nerd \
noto-fonts-emoji lxappearance xfce4-settings sddm-git sddm-sugar-candy-git 
```

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

