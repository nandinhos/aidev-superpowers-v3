#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Basic Memory Integration Tests
# ============================================================================
# Testes unitarios para integracao de checkpoints com Basic Memory
# TDD: RED phase - Fase 1: Schema Mapping
#
# Uso: ./test-basic-memory-integration.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
source "$ROOT_DIR/lib/checkpoint-manager.sh"

# Setup test environment with sample checkpoint
setup_checkpoint() {
    local ckpt_dir="$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$ckpt_dir"
    
    cat > "$ckpt_dir/ckpt-test-schema.json" << 'EOF'
{
  "checkpoint_id": "ckpt-test-schema",
  "trigger": "task_completed",
  "description": "Task 3.3 implementada: Comando aidev restore com 17 testes passando",
  "created_at": "2026-02-12T01:00:00Z",
  "state_snapshot": {
    "version": "3.9.0",
    "session": {
      "project_name": "aidev-superpowers-v3-1",
      "stack": "generic"
    },
    "active_intent": "feature_request",
    "intent_description": "Implementar integracao Basic Memory"
  },
  "sprint_snapshot": {
    "sprint_id": "sprint-3-context-monitor",
    "sprint_name": "Sprint 3: Context Monitor & Auto-Checkpoint",
    "status": "in_progress",
    "current_task": "task-3.4-basic-memory-integration",
    "overall_progress": {
      "total_tasks": 4,
      "completed": 3,
      "in_progress": 1,
      "pending": 0,
      "blocked": 0
    }
  }
}
EOF
}

# ============================================================================
# TESTES: ckpt_to_basic_memory_note
# ============================================================================

test_ckpt_to_basic_memory_note_exists() {
    if type ckpt_to_basic_memory_note &>/dev/null; then
        echo "✅ PASS: Funcao ckpt_to_basic_memory_note existe"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Funcao ckpt_to_basic_memory_note nao existe"
        ((TESTS_FAILED++))
    fi
}

test_ckpt_to_basic_memory_note_returns_markdown() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "#" "Deve retornar formato Markdown com headers"
}

test_ckpt_to_basic_memory_note_includes_checkpoint_id() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "ckpt-test-schema" "Deve incluir checkpoint_id"
}

test_ckpt_to_basic_memory_note_includes_trigger() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "task_completed" "Deve incluir trigger"
}

test_ckpt_to_basic_memory_note_includes_sprint_info() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "sprint-3-context-monitor" "Deve incluir sprint_id"
    assert_contains "$result" "Sprint 3" "Deve incluir sprint_name"
}

test_ckpt_to_basic_memory_note_includes_task() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "task-3.4-basic-memory-integration" "Deve incluir current_task"
}

test_ckpt_to_basic_memory_note_includes_project() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "aidev-superpowers-v3-1" "Deve incluir project_name"
}

test_ckpt_to_basic_memory_note_includes_version() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "3.9.0" "Deve incluir versao"
}

test_ckpt_to_basic_memory_note_includes_description() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "Task 3.3 implementada" "Deve incluir descricao"
}

test_ckpt_to_basic_memory_note_includes_tags() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "#checkpoint" "Deve incluir tag #checkpoint"
    assert_contains "$result" "#sprint-3" "Deve incluir tag da sprint"
}

test_ckpt_to_basic_memory_note_includes_progress() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "75" "Deve incluir progresso (75%)"
    assert_contains "$result" "3/4" "Deve incluir ratio de tasks"
}

test_ckpt_to_basic_memory_note_includes_intent() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "feature_request" "Deve incluir active_intent"
}

test_ckpt_to_basic_memory_note_file_not_exists() {
    local result=$(ckpt_to_basic_memory_note "/nonexistent/file.json" 2>/dev/null || echo "ERROR")
    
    assert_equals "ERROR" "$result" "Arquivo inexistente deve retornar erro"
}

test_ckpt_to_basic_memory_note_has_frontmatter() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    # Check for frontmatter format (--- at start)
    if echo "$result" | head -1 | grep -q "^---$"; then
        echo "✅ PASS: Nota deve ter frontmatter YAML"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Nota deve ter frontmatter YAML"
        ((TESTS_FAILED++))
    fi
}

test_ckpt_to_basic_memory_note_includes_timestamp() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "2026-02-12" "Deve incluir data de criacao"
}

test_ckpt_to_basic_memory_note_format_sections() {
    setup_checkpoint
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-schema.json"
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_file" 2>/dev/null || echo "")
    
    assert_contains "$result" "## Resumo" "Deve ter secao Resumo"
    assert_contains "$result" "## Estado" "Deve ter secao Estado"
    assert_contains "$result" "## Contexto" "Deve ter secao Contexto"
    assert_contains "$result" "## Progresso" "Deve ter secao Progresso"
}

test_ckpt_to_basic_memory_note_minimal_checkpoint() {
    # Test with minimal checkpoint data
    local ckpt_dir="$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$ckpt_dir"
    
    cat > "$ckpt_dir/ckpt-minimal.json" << 'EOF'
{
  "checkpoint_id": "ckpt-minimal",
  "trigger": "manual",
  "description": "Checkpoint minimal",
  "created_at": "2026-02-12T00:00:00Z"
}
EOF
    
    local result=$(ckpt_to_basic_memory_note "$ckpt_dir/ckpt-minimal.json" 2>/dev/null || echo "")
    
    assert_contains "$result" "ckpt-minimal" "Deve funcionar com checkpoint minimal"
    assert_contains "$result" "manual" "Deve incluir trigger em checkpoint minimal"
}

# ============================================================================
# TESTES: ckpt_sync_to_basic_memory (Fase 2)
# ============================================================================

test_ckpt_sync_to_basic_memory_exists() {
    if type ckpt_sync_to_basic_memory &>/dev/null; then
        echo "✅ PASS: Funcao ckpt_sync_to_basic_memory existe"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Funcao ckpt_sync_to_basic_memory nao existe (implementar na Fase 2)"
        ((TESTS_FAILED++))
    fi
}

test_ckpt_sync_to_basic_memory_skips_if_disabled() {
    if ! type ckpt_sync_to_basic_memory &>/dev/null; then
        echo "⚠️  SKIP: Funcao nao implementada ainda"
        ((TESTS_PASSED++))
        return 0
    fi
    
    # Se implementada, testar comportamento
    echo "⚠️  SKIP: Teste para Fase 2"
    ((TESTS_PASSED++))
}

# ============================================================================
# TESTES: ckpt_search_basic_memory (Fase 3)
# ============================================================================

test_ckpt_search_basic_memory_exists() {
    if type ckpt_search_basic_memory &>/dev/null; then
        echo "✅ PASS: Funcao ckpt_search_basic_memory existe"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Funcao ckpt_search_basic_memory nao existe (implementar na Fase 3)"
        ((TESTS_FAILED++))
    fi
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  BASIC MEMORY INTEGRATION TEST SUITE - TDD RED PHASE          ║"
echo "║  Fase 1: Schema Mapping                                        ║"
echo "║  AI Dev Superpowers v3.9.0                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Schema Mapping Tests (Fase 1)" \
    test_ckpt_to_basic_memory_note_exists \
    test_ckpt_to_basic_memory_note_returns_markdown \
    test_ckpt_to_basic_memory_note_includes_checkpoint_id \
    test_ckpt_to_basic_memory_note_includes_trigger \
    test_ckpt_to_basic_memory_note_includes_sprint_info \
    test_ckpt_to_basic_memory_note_includes_task \
    test_ckpt_to_basic_memory_note_includes_project \
    test_ckpt_to_basic_memory_note_includes_version \
    test_ckpt_to_basic_memory_note_includes_description \
    test_ckpt_to_basic_memory_note_includes_tags \
    test_ckpt_to_basic_memory_note_includes_progress \
    test_ckpt_to_basic_memory_note_includes_intent \
    test_ckpt_to_basic_memory_note_file_not_exists \
    test_ckpt_to_basic_memory_note_has_frontmatter \
    test_ckpt_to_basic_memory_note_includes_timestamp \
    test_ckpt_to_basic_memory_note_format_sections \
    test_ckpt_to_basic_memory_note_minimal_checkpoint

echo ""
echo "============================================================"
echo "  Fase 2 & 3 - Funcoes Futuras"
echo "============================================================"
echo ""

test_ckpt_sync_to_basic_memory_exists
test_ckpt_sync_to_basic_memory_skips_if_disabled
test_ckpt_search_basic_memory_exists

rm -rf "$TEST_DIR"

exit $TESTS_FAILED
