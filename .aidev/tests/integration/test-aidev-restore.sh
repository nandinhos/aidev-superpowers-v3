#!/bin/bash

# ============================================================================
# Testes de Integracao: aidev restore
# ============================================================================
# Testa o fluxo completo de restauracao de checkpoints
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Carrega test framework
source "$PROJECT_ROOT/tests/helpers/test-framework.sh"

# Carrega modulos
source "$PROJECT_ROOT/lib/context-monitor.sh"
source "$PROJECT_ROOT/lib/checkpoint-manager.sh"

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

setup_test_env() {
    rm -rf "$TEST_DIR"
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    mkdir -p "$TEST_DIR/.aidev/state"

    cat > "$TEST_DIR/.aidev/state/unified.json" << 'UNIFIED'
{
  "version": "3.9.0",
  "session": {
    "id": "restore-test-session",
    "started_at": "2026-02-11T23:00:00Z",
    "project_name": "aidev-superpowers-v3-1"
  },
  "active_agent": "orchestrator",
  "active_intent": "feature_request",
  "intent_description": "Implementar Context Monitor",
  "sprint_context": {
    "sprint_id": "sprint-3-context-monitor",
    "status": "in_progress",
    "progress_percentage": 25
  }
}
UNIFIED

    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'SPRINT'
{
  "sprint_id": "sprint-3-context-monitor",
  "sprint_name": "Sprint 3: Context Monitor & Auto-Checkpoint",
  "status": "in_progress",
  "current_task": "task-3.2-checkpoint-manager",
  "overall_progress": {
    "total_tasks": 4,
    "completed": 1,
    "in_progress": 1,
    "pending": 2
  },
  "session_context": {
    "tokens_used_in_sprint": 45000,
    "checkpoints_created": 2,
    "sessions_count": 1
  }
}
SPRINT
}

# ============================================================================
# TESTES: Fluxo completo create -> list -> restore
# ============================================================================

test_integration_create_and_list() {
    setup_test_env

    ckpt_create "$TEST_DIR" "task_completed" "Context monitor implementado" >/dev/null
    ckpt_create "$TEST_DIR" "auto_checkpoint" "85% de tokens" >/dev/null

    local list=$(ckpt_list "$TEST_DIR")
    local count=$(echo "$list" | grep -c "ckpt-")
    [ "$count" -eq 2 ]
    assert_true $? "Cria 2 checkpoints e lista ambos"
}

test_integration_create_and_get_latest() {
    setup_test_env

    ckpt_create "$TEST_DIR" "manual" "Primeiro" >/dev/null
    sleep 1
    local second_id=$(ckpt_create "$TEST_DIR" "manual" "Segundo")

    local latest=$(ckpt_get_latest "$TEST_DIR")
    assert_equals "$second_id" "$latest" "get_latest retorna o segundo checkpoint"
}

test_integration_create_and_restore_prompt() {
    setup_test_env

    local ckpt_id=$(ckpt_create "$TEST_DIR" "auto_checkpoint" "Auto save 85%")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"

    local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
    assert_contains "$prompt" "RESTAURAR CONTEXTO" "Prompt tem header"
    assert_contains "$prompt" "sprint-3-context-monitor" "Prompt tem sprint ID"
    assert_contains "$prompt" "feature_request" "Prompt tem intent"
    assert_contains "$prompt" "task-3.2-checkpoint-manager" "Prompt tem task atual"
}

test_integration_restore_prompt_has_progress() {
    setup_test_env

    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Progress check")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"

    local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
    assert_contains "$prompt" "1/4" "Prompt mostra progresso 1/4"
}

# ============================================================================
# TESTES: Context Monitor + Checkpoint Manager integrados
# ============================================================================

test_integration_context_triggers_checkpoint() {
    setup_test_env

    # Simula 87% de uso
    local action=$(ctx_should_checkpoint 87)
    assert_equals "auto_checkpoint" "$action" "87% gera trigger auto_checkpoint"

    # Cria checkpoint automatico
    local ckpt_id=$(ckpt_create "$TEST_DIR" "$action" "Auto: 87% de contexto utilizado")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"

    local trigger=$(jq -r '.trigger' "$ckpt_file")
    assert_equals "auto_checkpoint" "$trigger" "Checkpoint salvo com trigger auto_checkpoint"
}

test_integration_force_save_at_95_percent() {
    setup_test_env

    local action=$(ctx_should_checkpoint 96)
    assert_equals "force_save" "$action" "96% gera trigger force_save"

    local ckpt_id=$(ckpt_create "$TEST_DIR" "$action" "EMERGENCIA: 96% de contexto")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"

    local trigger=$(jq -r '.trigger' "$ckpt_file")
    assert_equals "force_save" "$trigger" "Checkpoint de emergencia criado"
}

test_integration_metrics_updated_after_checkpoint() {
    setup_test_env

    ctx_update_session_metrics "$TEST_DIR" 170000

    local tokens=$(jq -r '.session_context.tokens_used_in_sprint' "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json")
    assert_equals "170000" "$tokens" "Metricas atualizadas no sprint-status.json"
}

test_integration_checkpoint_preserves_full_state() {
    setup_test_env

    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Full state test")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"

    # Verifica campos do state_snapshot
    local version=$(jq -r '.state_snapshot.version' "$ckpt_file")
    assert_equals "3.9.0" "$version" "Preserva versao"

    local agent=$(jq -r '.state_snapshot.active_agent' "$ckpt_file")
    assert_equals "orchestrator" "$agent" "Preserva agente ativo"

    # Verifica campos do sprint_snapshot
    local sprint_name=$(jq -r '.sprint_snapshot.sprint_name' "$ckpt_file")
    assert_contains "$sprint_name" "Context Monitor" "Preserva nome da sprint"
}

# ============================================================================
# EXECUCAO
# ============================================================================

run_test_suite "aidev restore Integration" \
    test_integration_create_and_list \
    test_integration_create_and_get_latest \
    test_integration_create_and_restore_prompt \
    test_integration_restore_prompt_has_progress \
    test_integration_context_triggers_checkpoint \
    test_integration_force_save_at_95_percent \
    test_integration_metrics_updated_after_checkpoint \
    test_integration_checkpoint_preserves_full_state
