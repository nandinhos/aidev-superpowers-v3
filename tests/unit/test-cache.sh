#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Cache Tests (TDD RED Phase)
# ============================================================================
# Testes para o módulo de cache de ativação
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source module under test (will fail until we create it)
if [ -f "$ROOT_DIR/lib/cache.sh" ]; then
    source "$ROOT_DIR/lib/core.sh"
    source "$ROOT_DIR/lib/cache.sh"
fi

# ============================================================================
# Test Setup
# ============================================================================

TEST_TEMP_DIR=""

setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    mkdir -p "$TEST_TEMP_DIR/.aidev/agents"
    mkdir -p "$TEST_TEMP_DIR/.aidev/skills"
    mkdir -p "$TEST_TEMP_DIR/.aidev/rules"
    
    # Create mock agent files
    echo "# Orchestrator Agent" > "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md"
    echo "# Backend Agent" > "$TEST_TEMP_DIR/.aidev/agents/backend.md"
    
    # Create mock skill dirs
    mkdir -p "$TEST_TEMP_DIR/.aidev/skills/brainstorming"
    mkdir -p "$TEST_TEMP_DIR/.aidev/skills/tdd"
    
    # Create mock rules
    echo "# Generic Rules" > "$TEST_TEMP_DIR/.aidev/rules/generic.md"
}

teardown_test_env() {
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ============================================================================
# Tests: Cache Generation
# ============================================================================

test_section "Cache Generation"

# Test: generate_activation_cache exists
setup_test_env
if type generate_activation_cache &>/dev/null; then
    assert_equals "0" "0" "generate_activation_cache function exists"
else
    assert_equals "exists" "missing" "generate_activation_cache function exists"
fi
teardown_test_env

# Test: cache generates valid JSON structure
setup_test_env
if type generate_activation_cache &>/dev/null; then
    cache_output=$(generate_activation_cache "$TEST_TEMP_DIR" 2>/dev/null)
    if echo "$cache_output" | grep -q '"version"'; then
        assert_equals "0" "0" "Cache contains version field"
    else
        assert_equals "has_version" "no_version" "Cache contains version field"
    fi
else
    assert_equals "function" "missing" "Cache contains version field (function missing)"
fi
teardown_test_env

# Test: cache lists agents correctly
setup_test_env
if type generate_activation_cache &>/dev/null; then
    cache_output=$(generate_activation_cache "$TEST_TEMP_DIR" 2>/dev/null)
    if echo "$cache_output" | grep -q 'orchestrator'; then
        assert_equals "0" "0" "Cache lists agents"
    else
        assert_equals "has_agents" "no_agents" "Cache lists agents"
    fi
else
    assert_equals "function" "missing" "Cache lists agents (function missing)"
fi
teardown_test_env

# ============================================================================
# Tests: Cache Validation
# ============================================================================

test_section "Cache Validation"

# Test: validate_cache_freshness exists
if type validate_cache_freshness &>/dev/null; then
    assert_equals "0" "0" "validate_cache_freshness function exists"
else
    assert_equals "exists" "missing" "validate_cache_freshness function exists"
fi

# Test: get_aidev_hash exists
if type get_aidev_hash &>/dev/null; then
    assert_equals "0" "0" "get_aidev_hash function exists"
else
    assert_equals "exists" "missing" "get_aidev_hash function exists"
fi

# ============================================================================
# Tests: Cache Retrieval
# ============================================================================

test_section "Cache Retrieval"

# Test: get_cached_activation exists
if type get_cached_activation &>/dev/null; then
    assert_equals "0" "0" "get_cached_activation function exists"
else
    assert_equals "exists" "missing" "get_cached_activation function exists"
fi

# Test: invalidate_cache exists
if type invalidate_cache &>/dev/null; then
    assert_equals "0" "0" "invalidate_cache function exists"
else
    assert_equals "exists" "missing" "invalidate_cache function exists"
fi

# ============================================================================
# Cleanup
# ============================================================================

teardown_test_env
