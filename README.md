# Hyprland-setup

This is the Hyprland install script.(Not Official). 

Fork from https://github.com/SolDoesTech/HyprV3

## Note of using
The default keybind will be in ~/.config/HyprV/hypr/hyprland-bind.conf.
PLEASE READ IT.
If you need to change the monitor setting, go to ~/.config/HyprV/hypr/hyprland-monitor.conf.

Hyprland plugins can now be installed from this repo script, and you can still install them manually.
NOTE that plugins often need reinstall/re-enable after Hyprland upgrade/reinstall.

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

Install plugins during script run:

```bash
./set-hypr --install-hypr-plugins
```

Logs are written to `install.log` by default (customizable with `--log-file`).

## Full manual install guide (from zero)

This is a full manual flow without relying on `./set-hypr` automation.

1. Install base tools and an AUR helper (`yay`)

```bash
sudo pacman -Syu --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
```

2. Clone this repo

```bash
git clone https://github.com/gfhdhytghd/hyprland-setup.git
cd hyprland-setup
```

3. Install package groups manually

```bash
# core
yay -S --needed --noconfirm \
  hyprland kitty jq mako wofi xdg-desktop-portal-hyprland swappy grim slurp \
  dolphin ninja meson cmake polkit-gnome pamixer pavucontrol brightnessctl \
  bluez bluez-utils blueman network-manager-applet gvfs file-roller btop \
  pacman-contrib swww swaylock-effects wlogout

# theme (optional but recommended)
yay -S --needed --noconfirm \
  starship ttf-jetbrains-mono-nerd noto-fonts-emoji lxappearance xfce4-settings \
  qt5-svg qt5-quickcontrols2 qt5-graphicaleffects sddm

# apps (optional)
yay -S --needed --noconfirm \
  python-requests kweather ruby-fusuma google-chrome
```

4. Deploy config to `~/.config`

```bash
cp -a HyprV ~/.config/

ln -sfn ~/.config/HyprV/hypr ~/.config/hypr
ln -sfn ~/.config/HyprV/mako ~/.config/mako
ln -sfn ~/.config/HyprV/swaylock ~/.config/swaylock
ln -sfn ~/.config/HyprV/waybar ~/.config/waybar
ln -sfn ~/.config/HyprV/wlogout ~/.config/wlogout
ln -sfn ~/.config/HyprV/wofi ~/.config/wofi
ln -sfn ~/.config/HyprV/fusuma ~/.config/fusuma
ln -sfn ~/.config/HyprV/rofi ~/.config/rofi
ln -sfn ~/.config/HyprV/swaync ~/.config/swaync
ln -sfn ~/.config/HyprV/alacritty ~/.config/alacritty
ln -sfn ~/.config/HyprV/Konsole ~/.config/Konsole
ln -sfn ~/.config/HyprV/kitty ~/.config/kitty

chmod +x ~/.config/HyprV/hyprv_util ~/.config/HyprV/toggle
find ~/.config/HyprV/waybar/scripts ~/.config/HyprV/hypr/scripts -type f -exec chmod +x {} \;
touch ~/.Xresources
```

5. Enable services

```bash
sudo systemctl enable --now bluetooth.service
sudo systemctl enable sddm.service
```

6. (Optional) Install NVIDIA-related packages

```bash
yay -S --needed --noconfirm \
  linux-headers nvidia-dkms qt5-wayland qt5ct libva libva-nvidia-driver-git
```

7. Install Hyprland plugins with `hyprpm`

```bash
hyprpm update
hyprpm add https://github.com/ernestoCruz05/hycov
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm add https://github.com/horriblename/hyprgrass
hyprpm enable hyprgrass
hyprpm enable hycov
hyprpm enable hyprscrolling
hyprpm reload -n
```

8. Reboot or log out/in, then start Hyprland from your display manager.

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
