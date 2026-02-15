#!/usr/bin/env bash

AUR_HELPER="${AUR_HELPER:-}"

normalize_package_name() {
    local spec="$1"
    if [[ "$spec" == */* ]]; then
        echo "${spec#*/}"
    else
        echo "$spec"
    fi
}

detect_aur_helper() {
    local preferred="${1:-auto}"

    case "$preferred" in
        yay|paru)
            if command_exists "$preferred"; then
                AUR_HELPER="$preferred"
                log_ok "Using AUR helper: $AUR_HELPER"
                return 0
            fi
            die "Requested AUR helper '$preferred' was not found" 2
            ;;
        auto)
            if command_exists yay; then
                AUR_HELPER="yay"
            elif command_exists paru; then
                AUR_HELPER="paru"
            else
                die "No supported AUR helper found (yay/paru)" 2
            fi
            log_ok "Using AUR helper: $AUR_HELPER"
            ;;
        *)
            die "Invalid --aur-helper value: $preferred" 1
            ;;
    esac
}

pkg_installed() {
    local spec="$1"
    local pkg_name
    pkg_name="$(normalize_package_name "$spec")"
    pacman -Q "$pkg_name" >/dev/null 2>&1
}

install_package() {
    local spec="$1"

    if pkg_installed "$spec"; then
        log_ok "Package already installed: $(normalize_package_name "$spec")"
        return 0
    fi

    if ! run_cmd "Installing package $spec" "$AUR_HELPER" -S --needed --noconfirm "$spec"; then
        return 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    if pkg_installed "$spec"; then
        log_ok "Installed package: $(normalize_package_name "$spec")"
        return 0
    fi

    log_error "Install reported success but package missing: $spec"
    return 1
}

install_packages_from_file() {
    local file="$1"
    local fail_count=0
    local line

    if [[ ! -f "$file" ]]; then
        die "Package list not found: $file" 2
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(trim_whitespace "$line")"
        if [[ -z "$line" ]]; then
            continue
        fi

        if ! install_package "$line"; then
            fail_count=$((fail_count + 1))
        fi
    done <"$file"

    if (( fail_count > 0 )); then
        log_error "${fail_count} package(s) failed from $(basename "$file")"
        return 1
    fi

    return 0
}

install_nvidia_packages() {
    local list_file="$1"
    install_packages_from_file "$list_file"
}
