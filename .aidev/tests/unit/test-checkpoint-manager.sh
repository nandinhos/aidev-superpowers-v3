#!/bin/bash

# ============================================================================
# Testes Unitarios: Checkpoint Manager
# ============================================================================
# Testa funcoes de gestao de checkpoints automaticos
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Carrega test framework
source "$PROJECT_ROOT/tests/helpers/test-framework.sh"

# Setup: cria diretorio temporario para testes
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

setup_test_env() {
    rm -rf "$TEST_DIR"
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    mkdir -p "$TEST_DIR/.aidev/state"

    # unified.json minimo
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'UNIFIED'
{
  "version": "3.9.0",
  "session": {
    "id": "test-session-123",
    "started_at": "2026-02-11T23:00:00Z",
    "project_name": "test-project"
  },
  "active_agent": "orchestrator",
  "active_intent": "feature_request",
  "sprint_context": {
    "sprint_id": "sprint-3-test",
    "status": "in_progress"
  }
}
UNIFIED

    # sprint-status.json minimo
    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'SPRINT'
{
  "sprint_id": "sprint-3-test",
  "sprint_name": "Sprint 3: Test",
  "status": "in_progress",
  "current_task": "task-3.1",
  "overall_progress": {
    "total_tasks": 4,
    "completed": 1,
    "in_progress": 1,
    "pending": 2
  },
  "session_context": {
    "tokens_used_in_sprint": 50000,
    "checkpoints_created": 0,
    "sessions_count": 1
  }
}
SPRINT
}

# Carrega modulo sob teste
source "$PROJECT_ROOT/lib/context-monitor.sh"
source "$PROJECT_ROOT/lib/checkpoint-manager.sh"

# ============================================================================
# TESTES: ckpt_create
# ============================================================================

test_ckpt_create_generates_json_file() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "task_completed" "Tarefa 3.1 finalizada")

    [ -n "$ckpt_id" ]
    assert_true $? "ckpt_create retorna um checkpoint ID"
}

test_ckpt_create_file_exists() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "task_completed" "Tarefa 3.1 finalizada")
    local ckpt_dir="$TEST_DIR/.aidev/state/sprints/current/checkpoints"

    local found=$(ls "$ckpt_dir"/*.json 2>/dev/null | wc -l)
    [ "$found" -gt 0 ]
    assert_true $? "Arquivo de checkpoint criado no diretorio correto"
}

test_ckpt_create_contains_trigger() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "auto_checkpoint" "85% de contexto")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local trigger=$(jq -r '.trigger' "$ckpt_file")
    assert_equals "auto_checkpoint" "$trigger" "Checkpoint contem trigger correto"
}

test_ckpt_create_contains_description() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Checkpoint manual do usuario")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local desc=$(jq -r '.description' "$ckpt_file")
    assert_equals "Checkpoint manual do usuario" "$desc" "Checkpoint contem descricao"
}

test_ckpt_create_snapshots_unified_state() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "task_completed" "Snapshot test")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local session_id=$(jq -r '.state_snapshot.session.id' "$ckpt_file")
    assert_equals "test-session-123" "$session_id" "Checkpoint faz snapshot do unified.json"
}

test_ckpt_create_snapshots_sprint_progress() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "task_completed" "Progress test")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local completed=$(jq -r '.sprint_snapshot.overall_progress.completed' "$ckpt_file")
    assert_equals "1" "$completed" "Checkpoint inclui progresso da sprint"
}

test_ckpt_create_has_timestamp() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Timestamp test")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local ts=$(jq -r '.created_at' "$ckpt_file")
    [ "$ts" != "null" ] && [ -n "$ts" ]
    assert_true $? "Checkpoint tem timestamp"
}

test_ckpt_create_increments_counter() {
    setup_test_env
    ckpt_create "$TEST_DIR" "manual" "First" >/dev/null
    ckpt_create "$TEST_DIR" "manual" "Second" >/dev/null

    local count=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | wc -l)
    assert_equals "2" "$count" "Dois checkpoints criados"
}

# ============================================================================
# TESTES: ckpt_list
# ============================================================================

test_ckpt_list_empty() {
    setup_test_env
    # Remove qualquer checkpoint existente
    rm -f "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null

    local list=$(ckpt_list "$TEST_DIR")
    assert_equals "" "$list" "Lista vazia quando nao ha checkpoints"
}

test_ckpt_list_returns_entries() {
    setup_test_env
    ckpt_create "$TEST_DIR" "manual" "First" >/dev/null
    ckpt_create "$TEST_DIR" "auto" "Second" >/dev/null

    local list=$(ckpt_list "$TEST_DIR")
    local count=$(echo "$list" | grep -c "ckpt-")
    [ "$count" -ge 2 ]
    assert_true $? "ckpt_list retorna entradas de checkpoints"
}

# ============================================================================
# TESTES: ckpt_get_latest
# ============================================================================

test_ckpt_get_latest_returns_most_recent() {
    setup_test_env
    ckpt_create "$TEST_DIR" "manual" "Older" >/dev/null
    sleep 1
    local latest_id=$(ckpt_create "$TEST_DIR" "manual" "Newer")

    local got=$(ckpt_get_latest "$TEST_DIR")
    assert_contains "$got" "$latest_id" "ckpt_get_latest retorna o mais recente"
}

test_ckpt_get_latest_empty() {
    setup_test_env
    rm -f "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null

    local got=$(ckpt_get_latest "$TEST_DIR")
    assert_equals "" "$got" "ckpt_get_latest retorna vazio se nao ha checkpoints"
}

# ============================================================================
# TESTES: ckpt_generate_restore_prompt
# ============================================================================

test_generate_restore_prompt_contains_context() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Restore test")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
    assert_contains "$prompt" "RESTAURAR CONTEXTO" "Prompt contem header de restauracao"
}

test_generate_restore_prompt_contains_sprint_info() {
    setup_test_env
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Sprint info test")
    local ckpt_file=$(ls "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/*.json 2>/dev/null | tail -1)

    local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
    assert_contains "$prompt" "sprint-3-test" "Prompt contem sprint ID"
}

# ============================================================================
# EXECUCAO
# ============================================================================

run_test_suite "Checkpoint Manager" \
    test_ckpt_create_generates_json_file \
    test_ckpt_create_file_exists \
    test_ckpt_create_contains_trigger \
    test_ckpt_create_contains_description \
    test_ckpt_create_snapshots_unified_state \
    test_ckpt_create_snapshots_sprint_progress \
    test_ckpt_create_has_timestamp \
    test_ckpt_create_increments_counter \
    test_ckpt_list_empty \
    test_ckpt_list_returns_entries \
    test_ckpt_get_latest_returns_most_recent \
    test_ckpt_get_latest_empty \
    test_generate_restore_prompt_contains_context \
    test_generate_restore_prompt_contains_sprint_info
