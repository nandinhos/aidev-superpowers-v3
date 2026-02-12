#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Checkpoint Manager Tests
# ============================================================================
# Testes unitarios para o modulo checkpoint-manager.sh
# TDD: RED phase
#
# Uso: ./test-checkpoint-manager.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
source "$ROOT_DIR/lib/checkpoint-manager.sh"

setup_test_env() {
    ensure_dir "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$TEST_DIR/.aidev/state"
}

create_mock_unified() {
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "3.9.0",
  "session": {
    "id": "test-session-001",
    "project_name": "test-project"
  },
  "active_intent": "feature_request",
  "intent_description": "Test feature"
}
EOF
}

create_mock_sprint_status() {
    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{
  "sprint_id": "sprint-test",
  "sprint_name": "Test Sprint",
  "status": "in_progress",
  "current_task": "task-1",
  "overall_progress": {
    "total_tasks": 5,
    "completed": 2,
    "in_progress": 1,
    "pending": 2
  }
}
EOF
}

# TESTES: ckpt_create
test_ckpt_create_basic() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test checkpoint")
    assert_not_equals "" "$ckpt_id" "Deve retornar um checkpoint ID"
    assert_contains "$ckpt_id" "ckpt-" "ID deve comecar com 'ckpt-'"
}

test_ckpt_create_creates_file() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test checkpoint")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    assert_file_exists "$ckpt_file" "Arquivo de checkpoint deve ser criado"
}

test_ckpt_create_file_content() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "auto_checkpoint" "Auto save")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local trigger=$(jq -r '.trigger' "$ckpt_file")
        local desc=$(jq -r '.description' "$ckpt_file")
        assert_equals "auto_checkpoint" "$trigger" "Trigger deve ser 'auto_checkpoint'"
        assert_equals "Auto save" "$desc" "Descricao deve ser 'Auto save'"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_unique_ids() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local id1=$(ckpt_create "$TEST_DIR" "manual" "First")
    sleep 1
    local id2=$(ckpt_create "$TEST_DIR" "manual" "Second")
    assert_not_equals "$id1" "$id2" "IDs devem ser unicos"
}

# TESTES: ckpt_list
test_ckpt_list_empty() {
    # Create fresh isolated test dir for this test
    local isolated_dir="$(mktemp -d)"
    ensure_dir "$isolated_dir/.aidev/state/sprints/current/checkpoints"
    local result=$(ckpt_list "$isolated_dir")
    assert_equals "" "$result" "Lista vazia quando nao ha checkpoints"
    rm -rf "$isolated_dir"
}

test_ckpt_list_single() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Single")
    local result=$(ckpt_list "$TEST_DIR")
    assert_contains "$result" "$ckpt_id" "Lista deve conter o checkpoint criado"
}

test_ckpt_list_multiple() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local id1=$(ckpt_create "$TEST_DIR" "manual" "First")
    sleep 1
    local id2=$(ckpt_create "$TEST_DIR" "manual" "Second")
    local result=$(ckpt_list "$TEST_DIR")
    assert_contains "$result" "$id1" "Lista deve conter primeiro checkpoint"
    assert_contains "$result" "$id2" "Lista deve conter segundo checkpoint"
}

# TESTES: ckpt_get_latest
test_ckpt_get_latest_empty() {
    # Create fresh isolated test dir for this test
    local isolated_dir="$(mktemp -d)"
    ensure_dir "$isolated_dir/.aidev/state/sprints/current/checkpoints"
    local result=$(ckpt_get_latest "$isolated_dir")
    assert_equals "" "$result" "Latest vazio quando nao ha checkpoints"
    rm -rf "$isolated_dir"
}

test_ckpt_get_latest_single() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Only one")
    local result=$(ckpt_get_latest "$TEST_DIR")
    assert_equals "$ckpt_id" "$result" "Latest deve ser o unico checkpoint"
}

test_ckpt_get_latest_multiple() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local id1=$(ckpt_create "$TEST_DIR" "manual" "First")
    sleep 1
    local id2=$(ckpt_create "$TEST_DIR" "manual" "Second")
    local result=$(ckpt_get_latest "$TEST_DIR")
    assert_equals "$id2" "$result" "Latest deve ser o checkpoint mais recente"
}

# TESTES: ckpt_generate_restore_prompt
test_ckpt_generate_restore_prompt_not_exists() {
    local result=$(ckpt_generate_restore_prompt "/nonexistent.json")
    assert_equals "" "$result" "Arquivo inexistente retorna vazio"
}

test_ckpt_generate_restore_prompt_basic() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test restore")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        assert_contains "$prompt" "RESTAURAR CONTEXTO" "Prompt deve ter titulo"
        assert_contains "$prompt" "$ckpt_id" "Prompt deve conter checkpoint ID"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_generate_restore_prompt_includes_project() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        assert_contains "$prompt" "PROJETO:" "Prompt deve conter secao PROJETO"
        assert_contains "$prompt" "test-project" "Prompt deve conter nome do projeto"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

# MAIN
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  CHECKPOINT MANAGER TEST SUITE - TDD RED PHASE                 ║"
echo "║  AI Dev Superpowers v3.9.0                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Checkpoint Manager Tests" \
    test_ckpt_create_basic \
    test_ckpt_create_creates_file \
    test_ckpt_create_file_content \
    test_ckpt_create_unique_ids \
    test_ckpt_list_empty \
    test_ckpt_list_single \
    test_ckpt_list_multiple \
    test_ckpt_get_latest_empty \
    test_ckpt_get_latest_single \
    test_ckpt_get_latest_multiple \
    test_ckpt_generate_restore_prompt_not_exists \
    test_ckpt_generate_restore_prompt_basic \
    test_ckpt_generate_restore_prompt_includes_project

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
