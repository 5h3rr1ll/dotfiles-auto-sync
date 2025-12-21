#!/usr/bin/env bash
# Logger library for dotfiles-auto-sync
# Provides colored logging functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Prompt user for yes/no
prompt_yes_no() {
    local prompt="$1"
    local response
    read -p "$(echo -e "${YELLOW}?${NC} $prompt (y/n): ")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

# File logging (for backup script)
log_to_file() {
    local log_file="${1:-$HOME/Library/Logs/de.sherrill.dotfiles-auto-sync.log}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $2" | tee -a "$log_file"
}

# Error handling for backup script
error_exit() {
    local log_file="${1:-$HOME/Library/Logs/de.sherrill.dotfiles-auto-sync.log}"
    local message="$2"
    log_to_file "$log_file" "ERROR: $message"
    exit 1
}
