#!/usr/bin/env bats
# Unit tests for deps.sh

load helpers

setup() {
    setup_test_env
    mock_brew
    mock_yadm
    source_lib "logger.sh"
}

teardown() {
    teardown_test_env
}

# Test detect_yadm_bin function
@test "detect_yadm_bin finds yadm in PATH" {
    source_lib "deps.sh"
    result=$(detect_yadm_bin)
    [[ -n "$result" ]]
}

@test "detect_yadm_bin returns empty string if yadm not found" {
    # Remove mock yadm from PATH temporarily
    export PATH="/usr/bin:/bin"
    source_lib "deps.sh"
    result=$(detect_yadm_bin)
    [[ -z "$result" ]]
}

# Test check_homebrew function - can be tested by mocking
@test "check_homebrew detects installed homebrew" {
    source_lib "deps.sh"
    # Mock brew command
    brew() { echo "Homebrew 3.6.0"; }
    export -f brew
    
    run check_homebrew
    [[ "$output" =~ "Homebrew" ]]
}

# Test check_yadm function - can be tested by mocking
@test "check_yadm detects installed yadm" {
    source_lib "deps.sh"
    # Mock yadm command
    yadm() { echo "yadm 3.0.0"; }
    export -f yadm
    
    run check_yadm
    [[ "$output" =~ "yadm" ]]
}

# Test parsing configuration file
@test "can read dotfiles configuration" {
    cat > "$TEST_TEMP_DIR/files.conf" << 'EOF'
# Comment line
~/.zshrc
~/.bashrc
~/.config/starship.toml
EOF
    
    # Count non-comment lines
    count=$(grep -v '^#' "$TEST_TEMP_DIR/files.conf" | grep -v '^$' | wc -l)
    [[ "$count" -eq 3 ]]
}
