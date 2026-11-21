#!/usr/bin/env bats
# Unit tests for backup-core.sh

# Source the helpers file
source "$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)/../helpers.sh"

setup() {
    setup_test_env
    source_lib "backup-core.sh"
    LOG_FILE="$TEST_LOG_DIR/test.log"
    export HOME="$TEST_HOME"
    touch "$TEST_HOME/.zshrc" "$TEST_HOME/.last"
}

teardown() {
    teardown_test_env
}

# Fake yadm whose ls-remote succeeds or fails, counting calls
fake_yadm() {
    local exit_code="$1"
    YADM_BIN="$TEST_TEMP_DIR/fake-yadm"
    cat > "$YADM_BIN" << EOF
#!/bin/bash
echo call >> "$TEST_TEMP_DIR/calls"
exit $exit_code
EOF
    chmod +x "$YADM_BIN"
}

@test "load_files_to_backup reads last line without trailing newline" {
    printf '%s\n%s' '~/.zshrc' '~/.last' > "$TEST_TEMP_DIR/files.conf"
    run load_files_to_backup "$TEST_TEMP_DIR/files.conf"
    [ "$status" -eq 0 ]
    [[ "$output" == *"$TEST_HOME/.zshrc"* ]]
    [[ "$output" == *"$TEST_HOME/.last"* ]]
}

@test "load_files_to_backup skips comments and blank lines" {
    printf '# comment\n\n~/.zshrc\n' > "$TEST_TEMP_DIR/files.conf"
    run load_files_to_backup "$TEST_TEMP_DIR/files.conf"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_HOME/.zshrc" ]
}

@test "remote_reachable succeeds on first attempt when remote answers" {
    fake_yadm 0
    DOTFILES_SYNC_NET_RETRIES=3 DOTFILES_SYNC_NET_DELAY=0 run remote_reachable
    [ "$status" -eq 0 ]
    [ "$(wc -l < "$TEST_TEMP_DIR/calls")" -eq 1 ]
}

@test "remote_reachable retries and fails when remote is unreachable" {
    fake_yadm 128
    DOTFILES_SYNC_NET_RETRIES=3 DOTFILES_SYNC_NET_DELAY=0 run remote_reachable
    [ "$status" -eq 1 ]
    [ "$(wc -l < "$TEST_TEMP_DIR/calls")" -eq 3 ]
    grep -q "Remote not reachable (attempt 3/3)" "$LOG_FILE"
}
