#!/usr/bin/env bash
# Test helper utilities for dotfiles-auto-sync tests

# Setup test environment
setup_test_env() {
    # Create temporary test directory
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$TEST_HOME"
    
    # Create temporary logs directory
    export TEST_LOG_DIR="$TEST_TEMP_DIR/logs"
    mkdir -p "$TEST_LOG_DIR"
    
    # Create temporary git repo for testing
    export TEST_GIT_REPO="$TEST_TEMP_DIR/test-repo"
    mkdir -p "$TEST_GIT_REPO"
}

# Teardown test environment
teardown_test_env() {
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create mock yadm command
mock_yadm() {
    local mock_script="$TEST_TEMP_DIR/yadm"
    mkdir -p "$(dirname "$mock_script")"
    cat > "$mock_script" << 'EOF'
#!/bin/bash
# Mock yadm for testing
case "$1" in
    --version)
        echo "yadm 3.0.0"
        ;;
    rev-parse)
        [[ -d "$HOME/.yadm" ]] && echo ".yadm" && exit 0
        exit 1
        ;;
    remote)
        if [[ "$2" == "-v" ]]; then
            echo "origin  git@github.com:test/dotfiles.git (fetch)"
            echo "origin  git@github.com:test/dotfiles.git (push)"
        fi
        ;;
    *)
        exit 0
        ;;
esac
EOF
    chmod +x "$mock_script"
    export PATH="$TEST_TEMP_DIR:$PATH"
}

# Create mock brew command
mock_brew() {
    local mock_script="$TEST_TEMP_DIR/brew"
    mkdir -p "$(dirname "$mock_script")"
    cat > "$mock_script" << 'EOF'
#!/bin/bash
# Mock brew for testing
case "$1" in
    --version)
        echo "Homebrew 3.6.0"
        ;;
    *)
        exit 0
        ;;
esac
EOF
    chmod +x "$mock_script"
    export PATH="$TEST_TEMP_DIR:$PATH"
}

# Source library files for testing
source_lib() {
    local lib_name="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    source "$script_dir/lib/$lib_name"
}

# Assert function output contains text
assert_output_contains() {
    local output="$1"
    local expected="$2"
    if [[ ! "$output" =~ $expected ]]; then
        echo "FAIL: Expected output to contain '$expected', but got: $output"
        return 1
    fi
}

# Assert function exit code
assert_exit_code() {
    local actual="$1"
    local expected="$2"
    if [[ "$actual" -ne "$expected" ]]; then
        echo "FAIL: Expected exit code $expected, but got $actual"
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        echo "FAIL: File does not exist: $1"
        return 1
    fi
}

# Assert file does not exist
assert_file_not_exists() {
    if [[ -f "$1" ]]; then
        echo "FAIL: File should not exist: $1"
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    if [[ ! -d "$1" ]]; then
        echo "FAIL: Directory does not exist: $1"
        return 1
    fi
}
