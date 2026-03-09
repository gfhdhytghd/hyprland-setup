# Hyprland Setup

Personal Hyprland configuration, originally forked from <https://github.com/SolDoesTech/HyprV3>.

This repo keeps only the manual installation flow. There is no bundled installer script anymore.

## Notes

- Default keybinds live in `HyprV/hypr/hyprland-bind.conf`.
- Public monitor config stays generic. Keep machine-specific monitor presets only in your local `~/.config/HyprV/`.
- The lock screen uses `hyprlock`, with theme assets tracked as a git submodule at `HyprV/hypr/sakoora.hyprlock`.
- Overview is configured for `hymission`, not `hycov`.

## Manual Install

1. Install base tooling and an AUR helper.

```bash
sudo pacman -Syu --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
```

2. Clone this repo with submodules.

```bash
git clone --recurse-submodules https://github.com/gfhdhytghd/hyprland-setup.git
cd hyprland-setup
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

3. Install the package sets you want.

```bash
# Core + theme + optional apps
yay -S --needed $(awk -F/ '!/^#/ && NF == 2 {print $2}' \
  packages/core.txt \
  packages/theme.txt \
  packages/apps.txt)

# Optional NVIDIA stack
yay -S --needed $(awk -F/ '!/^#/ && NF == 2 {print $2}' packages/nvidia.txt)
```

4. Deploy the config into `~/.config`.

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
ln -sfn ~/.config/HyprV/ghostty ~/.config/ghostty
ln -sfn ~/.config/HyprV/Konsole ~/.config/Konsole

chmod +x ~/.config/HyprV/hyprv_util ~/.config/HyprV/toggle
find ~/.config/HyprV/waybar/scripts ~/.config/HyprV/hypr/scripts -type f -exec chmod +x {} \;
touch ~/.Xresources
```

5. Install the Hyprland plugins used by this config.

```bash
hyprpm update
hyprpm add https://github.com/gfhdhytghd/hymission
hyprpm add https://github.com/horriblename/hyprgrass
hyprpm enable hymission
hyprpm enable hyprgrass
hyprpm reload -n
```

6. Enable the services you want.

```bash
sudo systemctl enable --now bluetooth.service
sudo systemctl enable sddm.service
```

7. Log out/in or reboot, then start Hyprland from your display manager.

## Theme / Lock Notes

- `hyprlock` reads `~/.config/hypr/hyprlock.conf`.
- The theme assets referenced by that config come from the `sakoora.hyprlock` submodule.
- `HyprV/waybar/scripts/baraction` also toggles Ghostty colors. If you use it, make sure your preferred Qt/GTK theme tools are installed.

## Default Keybinds

- `ALT+SPACE`: app launcher
- `SUPER+Q`: terminal (`ghostty`)
- `SUPER+L`: lock screen (`hyprlock`)
- `SUPER+M`: logout menu
- `SUPER+E`: file manager
- `SUPER+S`: screenshot
- `SUPER+TAB`: `hymission` overview
- `SUPER+[1-0]`: switch workspace
- `SUPER+SHIFT+[1-0]`: move window to workspace
