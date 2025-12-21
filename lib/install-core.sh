#!/usr/bin/env bash
# Install core functionality for dotfiles-auto-sync

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/deps.sh"

# Configuration
PLIST_FILE="de.sherrill.dotfiles-auto-sync.plist"
PLIST_TEMPLATE="de.sherrill.dotfiles-auto-sync.plist.template"
FILES_CONFIG="files.conf"
FILES_TEMPLATE="files.conf.template"
LAUNCHAGENTS_DIR="$HOME/Library/LaunchAgents"
CONFIG_DIR="$SCRIPT_DIR/../config"

# Generate files config
generate_files_config() {
    log_header "Generating Files Configuration"

    local template_path="$CONFIG_DIR/$FILES_TEMPLATE"
    local config_path="$CONFIG_DIR/$FILES_CONFIG"

    if [[ ! -f "$template_path" ]]; then
        log_error "Template file not found: $template_path"
        return 1
    fi

    if [[ -f "$config_path" ]]; then
        log_warning "Config file already exists: $config_path"
        if ! prompt_yes_no "Replace existing config? (Your custom file list will be lost)"; then
            log_info "Keeping existing config"
            return 0
        fi
    fi

    log_info "Copying template to $config_path"
    cp "$template_path" "$config_path"
    log_success "Files config created"
    log_info "Edit $config_path to customize which files to backup"
}

# Install LaunchAgent
install_launchagent() {
    log_header "Installing LaunchAgent"

    local template_path="$CONFIG_DIR/$PLIST_TEMPLATE"
    local target_path="$LAUNCHAGENTS_DIR/$PLIST_FILE"
    local dotfiles_backup_path="$(cd "$SCRIPT_DIR/.." && pwd)"

    # Verify template exists
    if [[ ! -f "$template_path" ]]; then
        log_error "Template file not found: $template_path"
        return 1
    fi

    # Create LaunchAgents directory if it doesn't exist
    if [[ ! -d "$LAUNCHAGENTS_DIR" ]]; then
        log_info "Creating $LAUNCHAGENTS_DIR"
        mkdir -p "$LAUNCHAGENTS_DIR"
    fi

    # Check if plist already exists
    if [[ -f "$target_path" ]]; then
        log_warning "LaunchAgent already exists at $target_path"

        # Check if it's already loaded
        local launch_list=$(launchctl list 2>/dev/null || true)
        if echo "$launch_list" | grep -q "de.sherrill.dotfiles-auto-sync"; then
            log_info "Unloading existing LaunchAgent..."
            launchctl unload "$target_path" 2>/dev/null || true
        fi

        if prompt_yes_no "Replace existing LaunchAgent?"; then
            log_info "Removing old LaunchAgent..."
            rm "$target_path"
        else
            log_info "Keeping existing LaunchAgent"
            return 0
        fi
    fi

    # Generate plist from template
    log_info "Generating LaunchAgent plist for user: $USER"
    sed -e "s|{{HOME}}|$HOME|g" \
        -e "s|{{DOTFILES_BACKUP_PATH}}|$dotfiles_backup_path|g" \
        "$template_path" > "$target_path"

    log_success "LaunchAgent plist generated at $target_path"

    # Load the LaunchAgent
    log_info "Loading LaunchAgent..."
    if launchctl load "$target_path"; then
        log_success "LaunchAgent loaded successfully"
    else
        log_error "Failed to load LaunchAgent"
        return 1
    fi

    # Verify it's loaded
    if launchctl list | grep -q "de.sherrill.dotfiles-auto-sync"; then
        log_success "LaunchAgent is running"
        launchctl list | grep "de.sherrill.dotfiles-auto-sync" | sed 's/^/  /'
    else
        log_warning "LaunchAgent may not be running properly"
    fi
}

# Show post-installation information
show_install_summary() {
    log_header "Installation Complete!"

    local backup_script="$(cd "$SCRIPT_DIR/.." && pwd)/dotfiles-auto-sync"

    echo ""
    echo "The dotfiles backup system is now installed and running."
    echo ""
    echo "📋 What happens next:"
    echo "  • Your configured dotfiles are automatically backed up when modified"
    echo "  • Automatic backup runs daily as a safety net"
    echo "  • Logs are written to: ~/Library/Logs/de.sherrill.dotfiles-auto-sync.log"
    echo ""
    echo "🔧 Useful commands:"
    echo "  • Check status:  $backup_script status"
    echo "  • View logs:     $backup_script logs"
    echo "  • Test backup:   $backup_script backup"
    echo "  • Uninstall:     $backup_script uninstall"
    echo ""
    echo "📝 To customize which files to backup:"
    echo "  1. Edit: $CONFIG_DIR/$FILES_CONFIG"
    echo "  2. Uncomment the files you want to backup"
    echo "  3. Save the file - changes take effect on next backup"
    echo ""
    echo "💡 Tip: The config file is at $CONFIG_DIR/$FILES_CONFIG"
    echo ""

    if ! yadm rev-parse --git-dir &> /dev/null; then
        log_warning "Remember to initialize yadm to enable backups!"
        echo "  yadm init"
        echo "  yadm remote add origin <your-repo-url>"
        echo ""
    fi
}

# Main installation function
run_install() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Dotfiles Backup System - Installation             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    check_homebrew
    check_yadm
    check_yadm_init
    check_git_remote
    generate_files_config
    install_launchagent
    show_install_summary

    log_success "Installation completed successfully!"
}
