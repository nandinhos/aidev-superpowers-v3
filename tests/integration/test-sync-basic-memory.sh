#!/bin/bash

# ============================================================================
# Teste de Integracao: Sync Automatico com Basic Memory
# ============================================================================
# Valida que ckpt_create() integra corretamente com Basic Memory
#
# Uso: ./test-sync-integration.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
source "$ROOT_DIR/lib/checkpoint-manager.sh"

# Setup ambiente
setup_test_env() {
    ensure_dir "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$TEST_DIR/.aidev/state"
    
    # Mock unified.json
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "3.9.0",
  "session": {
    "project_name": "test-project",
    "stack": "generic"
  },
  "active_intent": "test",
  "intent_description": "Test sync"
}
EOF
    
    # Mock sprint-status.json
    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{
  "sprint_id": "sprint-test",
  "sprint_name": "Test Sprint",
  "status": "in_progress",
  "current_task": "task-test",
  "overall_progress": {
    "total_tasks": 4,
    "completed": 2,
    "in_progress": 1,
    "pending": 1
  }
}
EOF
}

# ============================================================================
# TESTES
# ============================================================================

test_ckpt_create_without_sync() {
    setup_test_env
    
    # Desabilita sync
    export CKPT_SYNC_BASIC_MEMORY="false"
    
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test checkpoint")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    
    assert_file_exists "$ckpt_file" "Checkpoint deve ser criado no filesystem"
}

test_ckpt_config_sync_enable() {
    local output=$(ckpt_config_sync true 2>&1)
    
    assert_contains "$output" "HABILITADO" "Deve confirmar habilitacao"
}

test_ckpt_config_sync_disable() {
    local output=$(ckpt_config_sync false 2>&1)
    
    assert_contains "$output" "DESABILITADO" "Deve confirmar desabilitacao"
}

test_ckpt_sync_status_disabled() {
    export CKPT_SYNC_BASIC_MEMORY="false"
    local output=$(ckpt_sync_status 2>&1)
    
    assert_contains "$output" "DESABILITADO" "Status deve mostrar desabilitado"
}

test_ckpt_sync_status_enabled() {
    export CKPT_SYNC_BASIC_MEMORY="true"
    local output=$(ckpt_sync_status 2>&1)
    
    assert_contains "$output" "HABILITADO" "Status deve mostrar habilitado"
}

test_ckpt_sync_all_no_checkpoints() {
    setup_test_env
    
    local output=$(ckpt_sync_all "$TEST_DIR" 2>&1)
    
    assert_contains "$output" "Nenhum checkpoint" "Deve informar quando nao ha checkpoints"
}

test_ckpt_sync_all_with_checkpoints() {
    setup_test_env
    
    # Cria alguns checkpoints
    ckpt_create "$TEST_DIR" "manual" "Checkpoint 1" >/dev/null
    ckpt_create "$TEST_DIR" "auto" "Checkpoint 2" >/dev/null
    
    # Mock do mcp__basic-memory__write_note para nao falhar
    mcp__basic-memory__write_note() {
        echo "Mock: Note created"
        return 0
    }
    export -f mcp__basic-memory__write_note
    
    local output=$(ckpt_sync_all "$TEST_DIR" 2>&1)
    
    assert_contains "$output" "sincronizados" "Deve sincronizar checkpoints"
}

test_ckpt_search_basic_memory_no_query() {
    local output=$(ckpt_search_basic_memory "" 2>&1)
    
    assert_contains "$output" "Uso:" "Deve mostrar uso quando sem query"
}

test_ckpt_to_basic_memory_note_integration() {
    setup_test_env
    
    # Cria checkpoint
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test integration")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    
    # Converte para nota
    local note=$(ckpt_to_basic_memory_note "$ckpt_file")
    
    assert_contains "$note" "$ckpt_id" "Nota deve conter checkpoint ID"
    assert_contains "$note" "Test integration" "Nota deve conter descricao"
    assert_contains "$note" "#checkpoint" "Nota deve ter tags"
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  SYNC AUTOMATICO - TESTES DE INTEGRACAO                        ║"
echo "║  Fase 2: Sincronizacao com Basic Memory                        ║"
echo "║  AI Dev Superpowers v3.9.0                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Sync Integration Tests" \
    test_ckpt_create_without_sync \
    test_ckpt_config_sync_enable \
    test_ckpt_config_sync_disable \
    test_ckpt_sync_status_disabled \
    test_ckpt_sync_status_enabled \
    test_ckpt_sync_all_no_checkpoints \
    test_ckpt_sync_all_with_checkpoints \
    test_ckpt_search_basic_memory_no_query \
    test_ckpt_to_basic_memory_note_integration

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
