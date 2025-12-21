#!/usr/bin/env bash
# Dependency checking library for dotfiles-auto-sync

# Source logger if not already loaded
if ! declare -f log_info >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/logger.sh"
fi

# Check if Homebrew is installed
check_homebrew() {
    log_header "Checking Homebrew"

    if command -v brew &> /dev/null; then
        log_success "Homebrew is installed: $(brew --version | head -n1)"
        return 0
    else
        log_warning "Homebrew is not installed"
        if prompt_yes_no "Would you like to install Homebrew now?"; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for Apple Silicon Macs
            if [[ $(uname -m) == "arm64" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi

            log_success "Homebrew installed successfully"
            return 0
        else
            log_error "Homebrew is required. Installation cancelled."
            exit 1
        fi
    fi
}

# Check and install yadm
check_yadm() {
    log_header "Checking yadm (Yet Another Dotfiles Manager)"

    if command -v yadm &> /dev/null; then
        log_success "yadm is installed: $(yadm --version)"
        return 0
    else
        log_warning "yadm is not installed"
        if prompt_yes_no "Would you like to install yadm via Homebrew?"; then
            log_info "Installing yadm..."
            brew install yadm
            log_success "yadm installed successfully"
            return 0
        else
            log_error "yadm is required. Installation cancelled."
            exit 1
        fi
    fi
}

# Detect yadm binary location (for LaunchAgent use)
detect_yadm_bin() {
    if command -v yadm &>/dev/null; then
        command -v yadm
    elif [[ -x "/opt/homebrew/bin/yadm" ]]; then
        echo "/opt/homebrew/bin/yadm"
    elif [[ -x "/usr/local/bin/yadm" ]]; then
        echo "/usr/local/bin/yadm"
    else
        echo ""
    fi
}

# Check if yadm is initialized
check_yadm_init() {
    log_header "Checking yadm Configuration"

    if yadm rev-parse --git-dir &> /dev/null; then
        log_success "yadm repository is initialized"

        # Check for remote
        if yadm remote -v &> /dev/null && [[ -n $(yadm remote -v) ]]; then
            log_success "yadm remote is configured:"
            yadm remote -v | sed 's/^/  /'
            return 0
        else
            log_warning "yadm repository exists but no remote is configured"
            log_info "You'll need to add a remote repository:"
            echo "  yadm remote add origin <your-repo-url>"
            if ! prompt_yes_no "Continue without remote configured? (You can add it later)"; then
                exit 1
            fi
            return 1
        fi
    else
        log_warning "yadm is not initialized"
        log_info "To initialize yadm, run:"
        echo ""
        echo "  yadm init"
        echo "  yadm remote add origin <your-repo-url>"
        echo "  yadm add ~/.zshrc ~/.zprofile ~/.config/starship.toml"
        echo "  yadm commit -m 'Initial dotfiles backup'"
        echo "  yadm push -u origin main"
        echo ""
        if ! prompt_yes_no "Continue without yadm initialized? (Required for backup to work)"; then
            exit 1
        fi
        return 1
    fi
}

# Check SSH keys and git remote access
check_git_remote() {
    log_header "Checking SSH Configuration for Git Push"

    local has_remote=false
    local remote_url=""

    # Check if yadm has a remote configured
    if yadm rev-parse --git-dir &> /dev/null; then
        remote_url=$(yadm remote get-url origin 2>/dev/null || echo "")
        if [[ -n "$remote_url" ]]; then
            has_remote=true
            log_info "yadm remote URL: $remote_url"
        fi
    fi

    # Detect which SSH key type exists
    local ssh_key_type=""
    local ssh_key_file=""
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        ssh_key_type="ed25519"
        ssh_key_file="$HOME/.ssh/id_ed25519"
    elif [[ -f "$HOME/.ssh/id_rsa" ]]; then
        ssh_key_type="rsa"
        ssh_key_file="$HOME/.ssh/id_rsa"
    fi

    # Check if SSH keys exist
    if [[ -n "$ssh_key_type" ]]; then
        log_success "SSH keys found in ~/.ssh/"
        ls -1 "$HOME/.ssh/id_"* 2>/dev/null | grep -v ".pub" | sed 's/^/  /' || true
    else
        log_warning "No SSH keys found in ~/.ssh/"
        log_info "To generate an SSH key:"
        echo ""
        echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
        echo ""
        log_info "Then add it to your git platform:"
        echo "  1. Copy the public key: cat ~/.ssh/id_ed25519.pub | pbcopy"
        echo "  2. Add to your git platform (GitHub/GitLab/Gitea):"
        echo "     • GitHub: Settings → SSH and GPG keys → New SSH key"
        echo "     • GitLab: Preferences → SSH Keys → Add new key"
        echo "     • Gitea: Settings → SSH / GPG Keys → Add Key"
        echo "  3. Paste the key and save"
        echo ""
        if ! prompt_yes_no "Continue without SSH keys configured?"; then
            exit 1
        fi
        return 0
    fi

    # Test GitHub SSH connection if remote is GitHub with SSH URL
    if [[ "$has_remote" == true ]] && [[ "$remote_url" =~ github\.com ]]; then
        if [[ "$remote_url" =~ ^git@ ]]; then
            log_info "Testing GitHub SSH connection..."
            # Capture SSH test output to avoid pipefail issues
            local ssh_test=$(ssh -T git@github.com 2>&1 || true)
            if echo "$ssh_test" | grep -q "successfully authenticated"; then
                log_success "GitHub SSH authentication successful"
                return 0
            else
                log_warning "Could not verify GitHub SSH authentication"
                log_info "This may be normal - proceeding with installation"
                log_info "If backups fail, verify your SSH key is added to your git platform"
                return 0
            fi
        elif [[ "$remote_url" =~ ^https:// ]]; then
            log_warning "yadm remote is using HTTPS (outdated)"
            log_info "Modern best practice is to use SSH. Would you like to switch?"
            echo ""
            echo "  Current: $remote_url"
            echo "  SSH:     git@github.com:5h3rr1ll/dotfiles.git"
            echo ""
            if prompt_yes_no "Switch yadm remote to SSH?"; then
                local ssh_url=$(echo "$remote_url" | sed 's|https://github.com/|git@github.com:|')
                yadm remote set-url origin "$ssh_url"
                log_success "Switched to SSH remote: $ssh_url"
                # Test SSH connection
                local ssh_test=$(ssh -T git@github.com 2>&1 || true)
                if echo "$ssh_test" | grep -q "successfully authenticated"; then
                    log_success "GitHub SSH authentication successful"
                else
                    log_info "SSH test inconclusive - will verify during first backup"
                fi
                return 0
            else
                log_info "Keeping HTTPS remote"
                return 0
            fi
        fi
    else
        log_info "Skipping SSH test (remote is not GitHub or not configured)"
        return 0
    fi
}
