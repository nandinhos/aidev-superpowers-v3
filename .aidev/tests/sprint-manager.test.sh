#!/bin/bash
# Testes para sprint-manager.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cria ambiente de teste temporario
TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

# Carrega biblioteca a ser testada (criara depois)
source "$SCRIPT_DIR/../lib/sprint-manager.sh" 2>/dev/null || true

TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Helpers
# ============================================================================

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

# Mock sprint-status.json
create_test_sprint_status() {
    local sprint_file="$TEST_DIR/.aidev/state/sprints/current/sprint-status.json"
    mkdir -p "$(dirname "$sprint_file")"

    cat > "$sprint_file" << 'EOF'
{
  "sprint_id": "sprint-2-knowledge-management",
  "sprint_name": "Sprint 2: Knowledge Management",
  "status": "in_progress",
  "overall_progress": {
    "total_tasks": 5,
    "completed": 5,
    "percentage": 100
  },
  "session_context": {
    "checkpoints_created": 7,
    "tokens_used_in_sprint": 12500
  },
  "next_action": {
    "task_id": "task-2.3-backlog",
    "description": "Iniciar sistema de backlog"
  }
}
EOF
}

# Mock unified.json
create_test_unified() {
    local unified_file="$TEST_DIR/.aidev/state/unified.json"
    mkdir -p "$(dirname "$unified_file")"

    cat > "$unified_file" << 'EOF'
{
  "version": "3.8.0",
  "session": {
    "current_fase": "3",
    "current_sprint": "4"
  },
  "active_skill": "release-management"
}
EOF
}

# ============================================================================
# Tests
# ============================================================================

test_sprint_get_current() {
    create_test_sprint_status

    local result=$(sprint_get_current "$TEST_DIR")
    assert_equals "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" "$result" "sprint_get_current retorna path correto"
}

test_sprint_get_current_empty_if_not_exists() {
    # Limpa qualquer arquivo de sprint anterior
    rm -rf "$TEST_DIR/.aidev/state/sprints"

    local result=$(sprint_get_current "$TEST_DIR")
    assert_equals "" "$result" "sprint_get_current retorna vazio se arquivo nao existe"
}

test_sprint_get_progress() {
    create_test_sprint_status

    local result=$(sprint_get_progress "$TEST_DIR")
    assert_contains "$result" "\"total_tasks\":5" "Retorna total_tasks"
    assert_contains "$result" "\"completed\":5" "Retorna completed"
}

test_sprint_sync_to_unified() {
    create_test_sprint_status
    create_test_unified

    sprint_sync_to_unified "$TEST_DIR"

    local unified_file="$TEST_DIR/.aidev/state/unified.json"
    assert_file_exists "$unified_file" "unified.json existe"

    if command -v jq >/dev/null 2>&1; then
        local sprint_id=$(jq -r '.sprint_context.sprint_id' "$unified_file")
        assert_equals "sprint-2-knowledge-management" "$sprint_id" "sprint_id sincronizado"

        local progress=$(jq -r '.sprint_context.progress_percentage' "$unified_file")
        assert_equals "100" "$progress" "progress_percentage sincronizado"
    fi
}

test_sprint_render_summary() {
    create_test_sprint_status

    local output=$(sprint_render_summary "$TEST_DIR")
    assert_contains "$output" "Sprint Atual:" "Mostra header"
    assert_contains "$output" "Sprint 2: Knowledge Management" "Mostra nome da sprint"
    assert_contains "$output" "Status:" "Mostra status"
    assert_contains "$output" "5/5" "Mostra progresso"
}

# ============================================================================
# Run Tests
# ============================================================================

echo ""
echo "=================================================="
echo "  Sprint Manager Tests"
echo "=================================================="
echo ""

test_sprint_get_current
test_sprint_get_current_empty_if_not_exists
test_sprint_get_progress
test_sprint_sync_to_unified
test_sprint_render_summary

# Cleanup
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "=================================================="
echo "  Test Summary"
echo "=================================================="
echo "  PASSED: $TESTS_PASSED"
echo "  FAILED: $TESTS_FAILED"
echo "=================================================="
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi

exit 0
