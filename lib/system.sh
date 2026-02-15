#!/usr/bin/env bash

sudo_ready() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] skipping sudo credential check"
        return 0
    fi

    run_cmd "Refreshing sudo credentials" sudo -v
}

backup_root_path() {
    local path="$1"
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi

    local backup="${path}.backup_$(ts)"
    run_sudo_cmd "Backing up $path to $backup" mv "$path" "$backup"
}

disable_wifi_powersave() {
    local loc="/etc/NetworkManager/conf.d/wifi-powersave.conf"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] write $loc"
        return 0
    fi

    run_sudo_cmd "Ensuring NetworkManager config directory" mkdir -p /etc/NetworkManager/conf.d
    printf "[connection]\nwifi.powersave = 2\n" | sudo tee "$loc" >>"$LOG_FILE" 2>&1
    run_sudo_cmd "Restarting NetworkManager" systemctl restart NetworkManager
}

configure_nvidia() {
    local nvidia_list="$1"

    install_nvidia_packages "$nvidia_list" || return 1

    local mkinitcpio_conf="/etc/mkinitcpio.conf"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] would update $mkinitcpio_conf"
    else
        local tmp_file
        tmp_file="$(mktemp)"
        awk '
            /^MODULES=/ {
                if ($0 !~ /nvidia/) {
                    sub(/\)$/, " nvidia nvidia_modeset nvidia_uvm nvidia_drm)")
                }
            }
            { print }
        ' "$mkinitcpio_conf" >"$tmp_file"
        run_sudo_cmd "Updating mkinitcpio modules for NVIDIA" cp "$tmp_file" "$mkinitcpio_conf"
        rm -f "$tmp_file"
    fi

    ensure_file_line "/etc/modprobe.d/nvidia.conf" "options nvidia-drm modeset=1"
    run_sudo_cmd "Regenerating initramfs" mkinitcpio -P
}

enable_service_list() {
    local services_csv="$1"
    local service

    split_csv "$services_csv"
    for service in "${SPLIT_RESULT[@]}"; do
        service="$(trim_whitespace "$service")"
        if [[ -z "$service" ]]; then
            continue
        fi

        case "$service" in
            bluetooth)
                run_sudo_cmd "Enabling bluetooth service" systemctl enable --now bluetooth.service
                ;;
            sddm)
                run_sudo_cmd "Enabling sddm service" systemctl enable sddm.service
                ;;
            *)
                log_warn "Unknown service in --enable-service: $service"
                ;;
        esac
    done
}

remove_conflicting_portals() {
    local portals=(xdg-desktop-portal-gnome xdg-desktop-portal-gtk)
    local pkg

    for pkg in "${portals[@]}"; do
        if pacman -Q "$pkg" >/dev/null 2>&1; then
            run_sudo_cmd "Removing conflicting portal $pkg" pacman -R --noconfirm "$pkg"
        else
            log_ok "Portal not installed, skipping: $pkg"
        fi
    done
}

install_toggle_binary() {
    local repo_root="$1"
    local src="$repo_root/HyprV/toggle"

    if ! missing_source "$src" "toggle helper"; then
        return 0
    fi

    run_sudo_cmd "Installing toggle helper to /usr/local/bin" install -m 0755 "$src" /usr/local/bin/toggle
}

add_user_to_input_group() {
    run_sudo_cmd "Adding $USER to input group" gpasswd -a "$USER" input
    log_note "Group membership change takes effect after logout/login."
}

apply_sddm_theme() {
    local repo_root="$1"
    local theme_src="$repo_root/Extras/sdt"
    local desktop_src="$repo_root/Extras/hyprland.desktop"
    local wallpaper_src="$HOME/.config/HyprV/backgrounds/v2-background-dark.jpg"
    local theme_dst="/usr/share/sddm/themes/sdt"

    if ! missing_source "$theme_src" "SDDM theme"; then
        return 0
    fi

    run_sudo_cmd "Ensuring SDDM theme directory" mkdir -p /usr/share/sddm/themes
    backup_root_path "$theme_dst"
    run_sudo_cmd "Installing SDDM theme" cp -a "$theme_src" "$theme_dst"

    run_sudo_cmd "Ensuring /etc/sddm.conf.d exists" mkdir -p /etc/sddm.conf.d

    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] write /etc/sddm.conf.d/10-theme.conf"
    else
        printf "[Theme]\nCurrent=sdt\n" | sudo tee /etc/sddm.conf.d/10-theme.conf >>"$LOG_FILE" 2>&1
        log_ok "Configured SDDM theme"
    fi

    if missing_source "$desktop_src" "hyprland.desktop"; then
        run_sudo_cmd "Ensuring wayland session directory" mkdir -p /usr/share/wayland-sessions
        run_sudo_cmd "Installing hyprland.desktop" cp "$desktop_src" /usr/share/wayland-sessions/hyprland.desktop
    fi

    if missing_source "$wallpaper_src" "SDDM wallpaper"; then
        run_sudo_cmd "Installing SDDM wallpaper" cp "$wallpaper_src" "$theme_dst/wallpaper.jpg"
    fi
}

install_wlogout_icons() {
    local icons_src="$HOME/.config/HyprV/wlogout/icons"

    if ! missing_source "$icons_src" "wlogout icons"; then
        return 0
    fi

    run_sudo_cmd "Ensuring /etc/wlogout-icon exists" mkdir -p /etc/wlogout-icon
    run_sudo_cmd "Copying wlogout icons" cp -af "$icons_src/." /etc/wlogout-icon/
}
