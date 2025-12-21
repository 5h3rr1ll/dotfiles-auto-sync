#!/usr/bin/env bash
# Test runner script for dotfiles-auto-sync
# Usage: ./run-tests.sh [unit|integration|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}✗ bats not found. Install with: brew install bats-core${NC}"
    exit 1
fi

# Default to all tests
TEST_TYPE="${1:-all}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Running $TEST_TYPE tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

failed=0

# Run unit tests
if [[ "$TEST_TYPE" == "unit" ]] || [[ "$TEST_TYPE" == "all" ]]; then
    echo ""
    echo -e "${BLUE}📋 Running unit tests...${NC}"
    if ! bats "$TEST_DIR/unit"/*.bats; then
        failed=$((failed + 1))
    else
        echo -e "${GREEN}✓ Unit tests passed${NC}"
    fi
fi

# Run integration tests
if [[ "$TEST_TYPE" == "integration" ]] || [[ "$TEST_TYPE" == "all" ]]; then
    echo ""
    echo -e "${BLUE}📋 Running integration tests...${NC}"
    if ! bats "$TEST_DIR/integration"/*.bats; then
        failed=$((failed + 1))
    else
        echo -e "${GREEN}✓ Integration tests passed${NC}"
    fi
fi

# Check shell script syntax
echo ""
echo -e "${BLUE}📋 Checking shell script syntax...${NC}"
for script in lib/*.sh dotfiles-auto-sync; do
    if bash -n "$script" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $script"
    else
        error_output=$(bash -n "$script" 2>&1)
        echo -e "${RED}✗${NC} $script"
        echo "  $error_output"
        failed=$((failed + 1))
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed (see details above)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
