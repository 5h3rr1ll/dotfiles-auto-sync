#!/usr/bin/env bats
# Unit tests for logger.sh

# Source the helpers file
source "$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)/../helpers.sh"

setup() {
    setup_test_env
    source_lib "logger.sh"
}

teardown() {
    teardown_test_env
}

# Test log_info function
@test "log_info outputs information message" {
    output=$(log_info "Test message" 2>&1)
    [[ "$output" =~ "Test message" ]]
}

@test "log_info includes info symbol" {
    output=$(log_info "Test" 2>&1)
    [[ "$output" =~ "ℹ" ]]
}

# Test log_success function
@test "log_success outputs success message" {
    output=$(log_success "Success message" 2>&1)
    [[ "$output" =~ "Success message" ]]
}

@test "log_success includes checkmark symbol" {
    output=$(log_success "Test" 2>&1)
    [[ "$output" =~ "✓" ]]
}

# Test log_warning function
@test "log_warning outputs warning message" {
    output=$(log_warning "Warning message" 2>&1)
    [[ "$output" =~ "Warning message" ]]
}

@test "log_warning includes warning symbol" {
    output=$(log_warning "Test" 2>&1)
    [[ "$output" =~ "⚠" ]]
}

# Test log_error function
@test "log_error outputs error message" {
    output=$(log_error "Error message" 2>&1)
    [[ "$output" =~ "Error message" ]]
}

@test "log_error includes error symbol" {
    output=$(log_error "Test" 2>&1)
    [[ "$output" =~ "✗" ]]
}

@test "log_error outputs to stderr" {
    # Redirect stderr to stdout to capture it
    output=$(log_error "Test error" 2>&1)
    [[ -n "$output" ]]
}

# Test log_header function
@test "log_header outputs header message" {
    output=$(log_header "Test Header" 2>&1)
    [[ "$output" =~ "Test Header" ]]
}

@test "log_header includes decorative borders" {
    output=$(log_header "Test" 2>&1)
    [[ "$output" =~ "━" ]]
}

# Test log_to_file function
@test "log_to_file creates log file and writes message" {
    log_to_file "$TEST_LOG_DIR/test.log" "Test message"
    assert_file_exists "$TEST_LOG_DIR/test.log"
}

@test "log_to_file includes timestamp" {
    log_to_file "$TEST_LOG_DIR/test.log" "Test message"
    content=$(cat "$TEST_LOG_DIR/test.log")
    [[ "$content" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]
}

@test "log_to_file appends to existing file" {
    log_to_file "$TEST_LOG_DIR/test.log" "First message"
    log_to_file "$TEST_LOG_DIR/test.log" "Second message"
    content=$(cat "$TEST_LOG_DIR/test.log")
    [[ "$content" =~ "First message" ]]
    [[ "$content" =~ "Second message" ]]
}

# Test error_exit function
@test "error_exit logs to file and exits with code 1" {
    run bash -c "
        source tests/helpers.sh
        source tests/../lib/logger.sh
        error_exit '$TEST_LOG_DIR/test.log' 'Test error'
    "
    [ $status -eq 1 ]
}
