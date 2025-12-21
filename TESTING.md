# Testing Guide

This document explains the testing strategy and how to run tests for dotfiles-auto-sync.

## Overview

The project uses **[bats](https://github.com/bats-core/bats-core)** (Bash Automated Testing Framework) for shell script testing. Tests are organized into unit and integration tests.

## Test Structure

```files
tests/
├── helpers.sh              # Shared test utilities and setup/teardown
├── unit/                   # Unit tests for individual functions
│   ├── logger.bats        # Tests for logger.sh
│   └── deps.bats          # Tests for deps.sh
├── integration/            # Integration tests for workflows
│   └── workflow.bats       # Tests for installation/sync workflows
└── fixtures/              # Test data and mock files
```

## Running Tests

### Quick Start

```bash
# Run all tests
./run-tests.sh

# Run only unit tests
./run-tests.sh unit

# Run only integration tests
./run-tests.sh integration

# Or use bats directly
bats tests/unit/*.bats
bats tests/integration/*.bats
```

### Prerequisites

Install bats-core:

```bash
brew install bats-core
```

## Test Categories

### Unit Tests

Unit tests verify individual functions in isolation.

**logger.bats**:

- ✅ Tests colored output functions (`log_info`, `log_success`, `log_warning`, `log_error`)
- ✅ Tests header formatting
- ✅ Tests file logging and timestamps
- ✅ Tests error exit handling

**deps.bats**:

- ✅ Tests dependency detection (yadm, homebrew)
- ✅ Tests configuration file parsing
- ✅ Tests yadm binary detection across different installation paths

### Integration Tests

Integration tests verify components working together.

**workflow.bats**:

- ✅ Tests plist template placeholder replacement
- ✅ Tests configuration file copying
- ✅ Tests dotfiles identification from config
- ✅ Tests commented/uncommented file handling

## Writing New Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

load helpers

setup() {
    setup_test_env
    source_lib "logger.sh"
}

teardown() {
    teardown_test_env
}

@test "description of what is tested" {
    run some_function
    [ $status -eq 0 ]
    [[ "$output" =~ "expected text" ]]
}
```

### Available Helper Functions

**Environment Setup:**

- `setup_test_env` - Create temp directories for testing
- `teardown_test_env` - Clean up temp directories
- `source_lib "lib.sh"` - Source library files for testing
- `mock_yadm` - Create mock yadm command
- `mock_brew` - Create mock brew command

**Assertions:**

- `assert_output_contains "output" "text"` - Check output contains text
- `assert_exit_code $code 0` - Check exit code
- `assert_file_exists "path"` - Check file exists
- `assert_file_not_exists "path"` - Check file doesn't exist
- `assert_dir_exists "path"` - Check directory exists

**Bats Built-in Assertions:**

- `[ $status -eq 0 ]` - Check exit status
- `[[ "$output" =~ "pattern" ]]` - Check output matches pattern
- `[ -f "file" ]` - File exists
- `[ -d "dir" ]` - Directory exists

## CI/CD Integration

Tests run automatically on:

- **Push** to `main` or `develop` branches
- **Pull Requests** against `main` or `develop`

### GitHub Actions Workflow

The workflow (`.github/workflows/tests.yml`) runs:

1. Unit tests
2. Integration tests
3. Shell syntax checks
4. ShellCheck linting (optional)

View results in the GitHub Actions tab.

## What's NOT Tested (By Design)

These areas are intentionally not automated in tests:

- ❌ **LaunchAgent activation** - Too environment-specific, requires macOS system access
- ❌ **Real git operations** - Would require test credentials and network access
- ❌ **Actual dotfiles modification** - Too dangerous, must be manual
- ❌ **System installation paths** - Would modify user's LaunchAgents directory

## Testing Best Practices

1. **Isolate tests** - Use temp directories, don't touch user files
2. **Mock external commands** - Don't call real `brew`, `git`, etc. in unit tests
3. **Test one thing** - Each test should verify one behavior
4. **Use clear names** - Test descriptions should explain what's being tested
5. **Clean up** - Always teardown temp files after tests

## Extending Tests

### To test a new function:

1. Create a test file in `tests/unit/` or `tests/integration/`
2. Source the library containing the function
3. Write tests using `@test` blocks
4. Run with `./run-tests.sh` to verify

### Example: Testing a new `backup-core.sh` function

```bash
#!/usr/bin/env bats

load helpers

setup() {
    setup_test_env
    source_lib "backup-core.sh"
}

teardown() {
    teardown_test_env
}

@test "git_add_dotfiles adds files to yadm" {
    mkdir -p "$TEST_HOME/.config"
    echo "test" > "$TEST_HOME/.zshrc"
    
    # Your test here
    run git_add_dotfiles "$TEST_HOME/.zshrc"
    [ $status -eq 0 ]
}
```

## Troubleshooting

**"bats not found"**

```bash
brew install bats-core
```

**Tests fail with "source not found"**

- Ensure you're running tests from the project root
- Check that `tests/helpers.sh` exists

**Permission denied**

```bash
chmod +x run-tests.sh
```

**Syntax errors in shell scripts**

```bash
bash -n lib/example.sh
shellcheck lib/example.sh
```

## References

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [Testing Bash Scripts](https://bash.cyberciti.biz/guide/Automated_Testing)
- [Shell Script Best Practices](https://mywiki.wooledge.org/BashGuide)
