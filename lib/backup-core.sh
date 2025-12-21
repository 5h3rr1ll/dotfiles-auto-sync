#!/usr/bin/env bash
# Backup core functionality for dotfiles-auto-sync

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logger.sh"
source "$SCRIPT_DIR/deps.sh"

# Configuration
LOG_FILE="$HOME/Library/Logs/de.sherrill.dotfiles-auto-sync.log"
CONFIG_DIR="$SCRIPT_DIR/../config"
FILES_CONFIG="$CONFIG_DIR/files.conf"

# Helper function to log directly to file without stdout
log_to_file_quiet() {
    local log_file="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$log_file"
}

# Load files to backup from config file
load_files_to_backup() {
    local config_file="$1"
    local files=()

    if [[ ! -f "$config_file" ]]; then
        log_to_file_quiet "$LOG_FILE" "ERROR: Config file not found: $config_file"
        log_to_file_quiet "$LOG_FILE" "Run 'dotfiles-auto-sync install' to generate it"
        exit 1
    fi

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue

        # Expand ~ to $HOME
        line="${line/#\~/$HOME}"
        # Trim whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        # Check if file exists
        if [[ -e "$line" ]]; then
            files+=("$line")
        else
            log_to_file_quiet "$LOG_FILE" "Warning: File not found, skipping: $line"
        fi
    done < "$config_file"

    if [[ ${#files[@]} -eq 0 ]]; then
        log_to_file_quiet "$LOG_FILE" "ERROR: No valid files to backup found in $config_file"
        log_to_file_quiet "$LOG_FILE" "Edit $config_file and uncomment files you want to backup"
        exit 1
    fi

    echo "${files[@]}"
}

# Main backup function
run_backup() {
    log_to_file "$LOG_FILE" "Starting dotfiles backup"

    # Detect yadm binary location
    YADM_BIN=$(detect_yadm_bin)

    # Verify yadm is installed
    if [[ -z "$YADM_BIN" ]] || [[ ! -x "$YADM_BIN" ]]; then
        error_exit "$LOG_FILE" "yadm not found in PATH. Install with: brew install yadm"
    fi

    log_to_file "$LOG_FILE" "Using yadm at: $YADM_BIN"

    # Change to home directory
    cd "$HOME" || error_exit "$LOG_FILE" "Failed to change to home directory"

    # Fetch and sync with remote first
    log_to_file "$LOG_FILE" "Fetching remote changes..."
    if ! "$YADM_BIN" fetch 2>&1 | tee -a "$LOG_FILE"; then
        log_to_file "$LOG_FILE" "Warning: Failed to fetch remote changes (continuing anyway)"
    fi

    # Check if there are uncommitted changes that would block pull
    stashed=false
    if ! "$YADM_BIN" diff-index --quiet HEAD -- 2>/dev/null; then
        log_to_file "$LOG_FILE" "Stashing uncommitted changes before sync..."
        if "$YADM_BIN" stash push -m "Auto-stash before backup sync" 2>&1 | tee -a "$LOG_FILE"; then
            stashed=true
        fi
    fi

    # Pull with rebase to sync with remote
    log_to_file "$LOG_FILE" "Syncing with remote repository..."
    pull_output=$("$YADM_BIN" pull --rebase 2>&1) || true
    echo "$pull_output" | tee -a "$LOG_FILE"

    # Restore stashed changes if we stashed them
    if [ "$stashed" = true ]; then
        log_to_file "$LOG_FILE" "Restoring stashed changes..."
        "$YADM_BIN" stash pop 2>&1 | tee -a "$LOG_FILE" || log_to_file "$LOG_FILE" "Warning: Failed to pop stash (may have conflicts)"
    fi

    # Load files from config
    local files_to_backup=($(load_files_to_backup "$FILES_CONFIG"))
    log_to_file "$LOG_FILE" "Loaded ${#files_to_backup[@]} file(s) from config"

    # Add files to yadm
    log_to_file "$LOG_FILE" "Adding files to yadm..."
    if ! "$YADM_BIN" add "${files_to_backup[@]}" 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "$LOG_FILE" "Failed to add files to yadm"
    fi

    # Commit changes
    log_to_file "$LOG_FILE" "Committing changes..."
    commit_output=$("$YADM_BIN" commit -m "$(date '+%Y-%m-%d %H:%M:%S') Automatic Backup" 2>&1) || true
    echo "$commit_output" | tee -a "$LOG_FILE"

    # Check for GPG signing failures
    if echo "$commit_output" | grep -q "gpg failed to sign the data\|signing failed: Timeout"; then
        log_error "GPG signing failed - automatic backup cannot proceed"
        log_error ""
        log_error "Reason: Your Git configuration requires commit signing, but GPG needs"
        log_error "manual passphrase entry which cannot be automated."
        log_error ""
        log_error "To complete the backup manually, run:"
        log_error "  yadm commit -m \"Manual backup \$(date '+%Y-%m-%d %H:%M:%S')\" && yadm push"
        log_error ""
        log_to_file "$LOG_FILE" "ERROR: GPG signing timeout - manual intervention required"
        exit 1
    fi

    # Check if there are any unpushed commits
    unpushed_commits=$("$YADM_BIN" log --oneline origin/master..HEAD 2>/dev/null | wc -l)

    # Check if there were changes to commit
    if echo "$commit_output" | grep -q "nothing to commit"; then
        if [ "$unpushed_commits" -eq 0 ]; then
            log_to_file "$LOG_FILE" "No changes to commit and no unpushed commits - everything up to date"
            exit 2
        else
            log_to_file "$LOG_FILE" "No new changes, but found $unpushed_commits unpushed commit(s) - pushing to remote"
        fi
    fi

    # Check if remote is configured
    if ! "$YADM_BIN" remote get-url origin &>/dev/null; then
        log_error "No remote repository configured for yadm"
        log_error ""
        log_error "To configure a remote repository, run:"
        log_error "  yadm remote add origin <your-repo-url>"
        log_error ""
        log_error "Examples:"
        log_error "  • GitHub:  yadm remote add origin git@github.com:username/dotfiles.git"
        log_error "  • GitLab:  yadm remote add origin git@gitlab.com:username/dotfiles.git"
        log_error "  • Gitea:   yadm remote add origin git@your-server:username/dotfiles.git"
        log_error ""
        log_to_file "$LOG_FILE" "ERROR: No remote repository configured - cannot push"
        exit 1
    fi

    # Push to remote
    log_to_file "$LOG_FILE" "Pushing to remote repository..."
    if ! "$YADM_BIN" push 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "$LOG_FILE" "Failed to push to remote repository"
    fi

    log_to_file "$LOG_FILE" "Backup completed successfully"
    exit 0
}
