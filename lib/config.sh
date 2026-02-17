#!/usr/bin/env bash

missing_source() {
    local src="$1"
    local label="$2"
    if [[ -e "$src" ]]; then
        return 0
    fi

    if [[ "$STRICT_MODE" == "true" ]]; then
        die "Missing required source for ${label}: ${src}" 4
    fi

    log_warn "Skipping ${label}; source not found: ${src}"
    return 1
}

link_path() {
    local src="$1"
    local dest="$2"

    if ! missing_source "$src" "$dest"; then
        return 0
    fi

    ensure_dir "$(dirname "$dest")"

    if [[ -L "$dest" ]]; then
        local current
        current="$(readlink -f "$dest" 2>/dev/null || true)"
        local target
        target="$(readlink -f "$src" 2>/dev/null || true)"
        if [[ -n "$current" && "$current" == "$target" ]]; then
            log_ok "Link already correct: $dest"
            return 0
        fi
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        backup_path "$dest"
    fi

    run_cmd "Linking $dest -> $src" ln -s "$src" "$dest"
}

ensure_user_line() {
    local file="$1"
    local line="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] ensure line in $file: $line"
        return 0
    fi

    touch "$file"
    if grep -Fxq "$line" "$file"; then
        log_ok "Line already present in $file"
        return 0
    fi

    echo "$line" >>"$file"
    log_ok "Updated $file"
}

deploy_hyprv_config() {
    local repo_root="$1"
    local src_hyprv="$repo_root/HyprV"
    local dst_hyprv="$HOME/.config/HyprV"

    missing_source "$src_hyprv" "HyprV tree" || return 1

    ensure_dir "$HOME/.config"

    if [[ -e "$dst_hyprv" || -L "$dst_hyprv" ]]; then
        backup_path "$dst_hyprv"
    fi

    run_cmd "Copying HyprV to $HOME/.config" cp -a "$src_hyprv" "$HOME/.config/"

    link_path "$dst_hyprv/hypr" "$HOME/.config/hypr"
    link_path "$dst_hyprv/mako" "$HOME/.config/mako"
    link_path "$dst_hyprv/swaylock" "$HOME/.config/swaylock"
    link_path "$dst_hyprv/waybar" "$HOME/.config/waybar"
    link_path "$dst_hyprv/wlogout" "$HOME/.config/wlogout"
    link_path "$dst_hyprv/wofi" "$HOME/.config/wofi"
    link_path "$dst_hyprv/fusuma" "$HOME/.config/fusuma"

    # Optional modules present in some variants of the config pack.
    link_path "$dst_hyprv/rofi" "$HOME/.config/rofi"
    link_path "$dst_hyprv/swaync" "$HOME/.config/swaync"
    link_path "$dst_hyprv/alacritty" "$HOME/.config/alacritty"
    link_path "$dst_hyprv/Konsole" "$HOME/.config/Konsole"
    link_path "$dst_hyprv/kitty" "$HOME/.config/kitty"

    shopt -s nullglob
    local exec_targets=(
        "$dst_hyprv/hyprv_util"
        "$dst_hyprv/toggle"
        "$dst_hyprv/waybar/scripts"/*
        "$dst_hyprv/hypr/scripts"/*
    )
    local target
    for target in "${exec_targets[@]}"; do
        if [[ -f "$target" ]]; then
            run_cmd "Marking executable: $target" chmod +x "$target"
        fi
    done
    shopt -u nullglob

    run_cmd "Ensuring $HOME/.Xresources exists" touch "$HOME/.Xresources"
}

apply_starship_config() {
    local repo_root="$1"
    local src="$repo_root/Extras/starship.toml"
    local dst="$HOME/.config/starship.toml"

    if ! missing_source "$src" "starship config"; then
        return 0
    fi

    ensure_dir "$HOME/.config"
    run_cmd "Copying starship config" cp "$src" "$dst"
    ensure_user_line "$HOME/.bashrc" 'eval "$(starship init bash)"'
}
