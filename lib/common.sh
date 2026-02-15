#!/usr/bin/env bash

# Shared helpers for logging, prompts and command execution.

CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CWR="[\e[1;35mWARN\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
AUTO_YES="${AUTO_YES:-false}"
DRY_RUN="${DRY_RUN:-false}"
STRICT_MODE="${STRICT_MODE:-false}"
LOG_FILE="${LOG_FILE:-install.log}"

print_line() {
    local level="$1"
    shift
    echo -e "$level - $*"
}

log_note() {
    print_line "$CNT" "$@"
}

log_ok() {
    print_line "$COK" "$@"
}

log_warn() {
    print_line "$CWR" "$@"
}

log_error() {
    print_line "$CER" "$@" >&2
}

log_action() {
    print_line "$CAC" "$@"
}

ts() {
    date +"%Y%m%d_%H%M%S"
}

die() {
    local message="$1"
    local code="${2:-1}"
    log_error "$message"
    exit "$code"
}

init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")" || die "Cannot create log directory for: $LOG_FILE" 2
    touch "$LOG_FILE" || die "Cannot write log file: $LOG_FILE" 2
    {
        echo
        echo "===== $(date -Iseconds) ====="
    } >>"$LOG_FILE"
}

on_error() {
    local line="$1"
    local cmd="$2"
    log_error "Failed at line ${line}: ${cmd}"
    log_error "See log: $LOG_FILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

confirm() {
    local prompt="$1"
    local default_answer="${2:-n}"
    local reply

    if [[ "$NON_INTERACTIVE" == "true" ]]; then
        if [[ "$AUTO_YES" == "true" ]]; then
            return 0
        fi
        [[ "$default_answer" == "y" ]]
        return $?
    fi

    local suffix="[y/N]"
    if [[ "$default_answer" == "y" ]]; then
        suffix="[Y/n]"
    fi

    while true; do
        read -r -p "${prompt} ${suffix} " reply
        reply="${reply:-$default_answer}"
        case "$reply" in
            y|Y) return 0 ;;
            n|N) return 1 ;;
            *) log_warn "Please answer y or n." ;;
        esac
    done
}

run_cmd() {
    local desc="$1"
    shift

    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] $desc"
        log_note "[dry-run] command: $*"
        return 0
    fi

    log_action "$desc"
    if "$@" >>"$LOG_FILE" 2>&1; then
        log_ok "$desc"
    else
        log_error "$desc failed"
        return 1
    fi
}

run_sudo_cmd() {
    local desc="$1"
    shift
    run_cmd "$desc" sudo "$@"
}

backup_path() {
    local path="$1"
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi

    local backup="${path}.backup_$(ts)"
    run_cmd "Backing up $path to $backup" mv "$path" "$backup"
}

ensure_dir() {
    local path="$1"
    run_cmd "Ensuring directory $path" mkdir -p "$path"
}

ensure_file_line() {
    local file="$1"
    local line="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_note "[dry-run] ensure line in $file: $line"
        return 0
    fi

    run_sudo_cmd "Ensuring directory for $file" mkdir -p "$(dirname "$file")"
    run_sudo_cmd "Ensuring file exists: $file" touch "$file"

    if sudo grep -Fxq "$line" "$file" 2>/dev/null; then
        log_ok "Line already present in $file"
        return 0
    fi

    echo "$line" | sudo tee -a "$file" >>"$LOG_FILE" 2>&1
}

split_csv() {
    local raw="$1"
    IFS=',' read -r -a SPLIT_RESULT <<<"$raw"
}

trim_whitespace() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf "%s" "$value"
}
