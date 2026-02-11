#!/bin/bash

# ============================================================================
# Test Framework - Common Helpers
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

assert_true() {
    local result="$1"
    local message="$2"

    if [ "$result" -eq 0 ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" = "$actual" ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message (expected: '$expected', got: '$actual')"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_equals() {
    local not_expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$not_expected" != "$actual" ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message (should not be: '$not_expected', got: '$actual')"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if echo "$haystack" | grep -q "$needle"; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message (não encontrado: '$needle')"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"

    if [ -f "$file" ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message (arquivo não existe: $file)"
        ((TESTS_FAILED++))
        return 1
    fi
}

ensure_dir() {
    local dir="$1"
    mkdir -p "$dir"
}

run_test_suite() {
    local suite_name="$1"
    shift
    local tests=("$@")

    echo ""
    echo "============================================================"
    echo "  Test Suite: $suite_name"
    echo "============================================================"
    echo ""

    for test_func in "${tests[@]}"; do
        echo "Running: $test_func"
        $test_func
        echo ""
    done

    echo "============================================================"
    echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "============================================================"

    if [ "$TESTS_FAILED" -gt 0 ]; then
        exit 1
    fi
}
