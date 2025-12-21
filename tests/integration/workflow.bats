#!/usr/bin/env bats
# Integration tests for installation and sync workflow

# Source the helpers file
source "$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)/../helpers.sh"

setup() {
    setup_test_env
    mock_brew
    mock_yadm
}

teardown() {
    teardown_test_env
}

# Test plist template substitution
@test "plist template has required placeholders" {
    plist_file="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)/../../config/de.sherrill.dotfiles-auto-sync.plist.template"
    [[ -f "$plist_file" ]]
    grep -q "{{HOME}}" "$plist_file"
    grep -q "{{DOTFILES_BACKUP_PATH}}" "$plist_file"
}

@test "can replace placeholders in plist" {
    # Create mock template
    cat > "$TEST_TEMP_DIR/template.plist" << 'EOF'
<string>{{HOME}}/.zshrc</string>
<string>{{DOTFILES_BACKUP_PATH}}/config</string>
EOF
    
    # Replace placeholders
    HOME_PATH="/Users/testuser"
    BACKUP_PATH="/Users/testuser/.dotfiles"
    
    result=$(sed "s|{{HOME}}|$HOME_PATH|g; s|{{DOTFILES_BACKUP_PATH}}|$BACKUP_PATH|g" "$TEST_TEMP_DIR/template.plist")
    
    [[ "$result" =~ "$HOME_PATH/.zshrc" ]]
    [[ "$result" =~ "$BACKUP_PATH/config" ]]
}

# Test config file copying
@test "files.conf template exists" {
    config_template="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)/../../config/files.conf.template"
    [[ -f "$config_template" ]]
}

@test "can read files.conf template" {
    config_template="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)/../../config/files.conf.template"
    content=$(cat "$config_template")
    [[ -n "$content" ]]
}

# Test workflow: create temp files and simulate backup
@test "can identify dotfiles to backup from config" {
    cat > "$TEST_TEMP_DIR/files.conf" << 'EOF'
# Test config
~/.zshrc
~/.bashrc
~/.config/starship.toml
EOF
    
    # Count configured files
    count=$(grep -v '^#' "$TEST_TEMP_DIR/files.conf" | grep -v '^$' | wc -l)
    [[ "$count" -eq 3 ]]
}

@test "backup config can include commented files" {
    cat > "$TEST_TEMP_DIR/files.conf" << 'EOF'
~/.zshrc
# ~/.bashrc
~/.config/starship.toml
EOF
    
    # Only uncommented lines should be counted
    active_count=$(grep -v '^#' "$TEST_TEMP_DIR/files.conf" | grep -v '^$' | wc -l)
    [[ "$active_count" -eq 2 ]]
}
