#!/usr/bin/env bash
# Uninstall core functionality for dotfiles-auto-sync

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"

# Configuration
PLIST_FILE="de.sherrill.dotfiles-auto-sync.plist"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCHAGENTS_DIR/$PLIST_FILE"
LOG_DIR="$HOME/Library/Logs"

# Unload and remove LaunchAgent
remove_launchagent() {
    log_header "Removing LaunchAgent"

    if [[ ! -f "$PLIST_PATH" ]]; then
        log_info "LaunchAgent not found at $PLIST_PATH"
        log_info "Nothing to uninstall"
        return 0
    fi

    # Check if loaded and unload
    # Note: Capture to variable first to avoid pipefail issues with grep -q
    local launch_list=$(launchctl list 2>/dev/null || true)
    if echo "$launch_list" | grep -q "de.sherrill.dotfiles-auto-sync"; then
        log_info "Unloading LaunchAgent..."
        if launchctl unload "$PLIST_PATH" 2>/dev/null; then
            log_success "LaunchAgent unloaded successfully"
        else
            log_warning "Failed to unload LaunchAgent (may not be running)"
        fi
    else
        log_info "LaunchAgent is not currently loaded"
    fi

    # Remove plist file
    log_info "Removing $PLIST_PATH"
    if rm "$PLIST_PATH"; then
        log_success "LaunchAgent removed successfully"
    else
        log_error "Failed to remove LaunchAgent"
        return 1
    fi
}

# Optionally remove log files
remove_logs() {
    log_header "Log Files"

    local log_files=(
        "$LOG_DIR/de.sherrill.dotfiles-auto-sync.log"
        "$LOG_DIR/de.sherrill.dotfiles-auto-sync_error.log"
    )

    local found_logs=false
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            found_logs=true
            log_info "Found: $log_file"
        fi
    done

    if [[ "$found_logs" == false ]]; then
        log_info "No log files found"
        return 0
    fi

    if prompt_yes_no "Remove log files?"; then
        for log_file in "${log_files[@]}"; do
            if [[ -f "$log_file" ]]; then
                log_info "Removing $log_file"
                rm "$log_file"
            fi
        done
        log_success "Log files removed"
    else
        log_info "Keeping log files"
    fi
}

# Show information about yadm
show_yadm_info() {
    log_header "yadm Configuration"

    log_info "The uninstaller does NOT remove:"
    echo "  • yadm (use 'brew uninstall yadm' if desired)"
    echo "  • Your yadm repository (~/.local/share/yadm/repo.git)"
    echo "  • Your dotfiles tracked by yadm"
    echo ""
    log_info "Your dotfiles backup repository remains intact and can be:"
    echo "  • Managed manually with yadm commands"
    echo "  • Reinstalled later with: dotfiles-auto-sync install"
    echo ""
}

# Show uninstall summary
show_uninstall_summary() {
    log_header "Uninstallation Complete!"

    local backup_script="$(cd "$SCRIPT_DIR/.." && pwd)/dotfiles-auto-sync"

    echo ""
    echo "The dotfiles backup LaunchAgent has been removed."
    echo ""
    echo "📋 What was removed:"
    echo "  • LaunchAgent: $PLIST_PATH"
    echo "  • Automatic backup scheduling"
    echo ""
    echo "📝 To reinstall:"
    echo "  • Run: $backup_script install"
    echo ""
}

# Main uninstallation function
run_uninstall() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       Dotfiles Backup System - Uninstallation             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    log_warning "This will remove the dotfiles backup LaunchAgent"
    echo ""

    if ! prompt_yes_no "Continue with uninstallation?"; then
        log_info "Uninstallation cancelled"
        exit 0
    fi

    remove_launchagent
    remove_logs
    show_yadm_info
    show_uninstall_summary

    log_success "Uninstallation completed successfully!"
}
