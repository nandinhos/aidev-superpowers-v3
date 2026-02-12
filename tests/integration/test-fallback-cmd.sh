#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Fallback Command Integration Tests
# ============================================================================
# Testes de integracao para o comando 'aidev fallback'
# Sprint 5 - Feature 5.3.3
#
# Uso: ./test-fallback-cmd.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"

# Setup aidev environment
setup_aidev_env() {
    # Limpa estado anterior
    rm -rf "$TEST_DIR/.aidev/state/fallback" 2>/dev/null || true
    rm -f "$TEST_DIR/.aidev/state/sprints/current/checkpoints"/ckpt-*.json 2>/dev/null || true

    ensure_dir "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$TEST_DIR/.aidev/state"
    ensure_dir "$TEST_DIR/lib"

    cp "$ROOT_DIR/lib/context-monitor.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/checkpoint-manager.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/fallback-generator.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/core.sh" "$TEST_DIR/lib/" 2>/dev/null || true

    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "4.0.0",
  "session": {
    "id": "test-session",
    "project_name": "test-project"
  },
  "active_intent": "feature_request",
  "intent_description": "Implementando fallback"
}
EOF

    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{
  "sprint_id": "sprint-5-estado-ubiquo",
  "sprint_name": "Sprint 5: Orquestracao por Estado Ubiquo",
  "status": "in_progress",
  "current_task": "task-5.3.3-cli-fallback",
  "overall_progress": {
    "total_tasks": 14,
    "completed": 6,
    "in_progress": 1,
    "pending": 7,
    "blocked": 0
  },
  "tasks": [
    {
      "task_id": "task-5.3.1-fallback-generator",
      "name": "Criar modulo fallback-generator.sh",
      "status": "completed",
      "feature": "5.3",
      "file": "lib/fallback-generator.sh"
    },
    {
      "task_id": "task-5.3.3-cli-fallback",
      "name": "Comando CLI aidev fallback",
      "status": "in_progress",
      "feature": "5.3",
      "file": "bin/aidev"
    }
  ]
}
EOF

    touch "$TEST_DIR/.aidev/.installed"
}

run_fallback() {
    cd "$TEST_DIR" && "$ROOT_DIR/bin/aidev" fallback "$@" 2>&1 || true
}

# Create a checkpoint so fallback generate has something to work with
create_test_checkpoint() {
    source "$ROOT_DIR/lib/checkpoint-manager.sh"
    ckpt_create "$TEST_DIR" "manual" "Test checkpoint for fallback" \
        "Implementando testes" "Tudo funciona" "Input -> Process -> Output" > /dev/null 2>&1
}

# ============================================================================
# TESTES: fallback generate
# ============================================================================

test_fallback_generate_basic() {
    setup_aidev_env
    create_test_checkpoint
    local result=$(run_fallback generate)
    assert_contains "$result" "fallback" "Deve confirmar geracao dos artefatos"
}

test_fallback_generate_creates_files() {
    setup_aidev_env
    create_test_checkpoint
    run_fallback generate > /dev/null 2>&1
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/last-checkpoint.md" "Deve criar last-checkpoint.md"
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/sprint-context.md" "Deve criar sprint-context.md"
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/reconstruction-guide.md" "Deve criar reconstruction-guide.md"
}

test_fallback_generate_checkpoint_content() {
    setup_aidev_env
    create_test_checkpoint
    run_fallback generate > /dev/null 2>&1
    local content
    content=$(cat "$TEST_DIR/.aidev/state/fallback/last-checkpoint.md" 2>/dev/null)
    assert_contains "$content" "Checkpoint" "last-checkpoint.md deve conter titulo"
    assert_contains "$content" "Implementando testes" "Deve conter chain_of_thought"
}

test_fallback_generate_without_checkpoint() {
    setup_aidev_env
    # Nao cria checkpoint - deve gerar sprint e guide mesmo assim
    run_fallback generate > /dev/null 2>&1
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/sprint-context.md" "Deve criar sprint-context.md mesmo sem checkpoint"
}

# ============================================================================
# TESTES: fallback show
# ============================================================================

test_fallback_show_no_artifacts() {
    setup_aidev_env
    local result=$(run_fallback show)
    assert_contains "$result" "Nenhum" "Show sem artefatos deve informar"
}

test_fallback_show_with_artifacts() {
    setup_aidev_env
    create_test_checkpoint
    run_fallback generate > /dev/null 2>&1
    local result=$(run_fallback show)
    assert_contains "$result" "Artefatos" "Show deve listar artefatos"
    assert_contains "$result" "last-checkpoint.md" "Show deve listar last-checkpoint.md"
}

# ============================================================================
# TESTES: fallback clean
# ============================================================================

test_fallback_clean_removes_files() {
    setup_aidev_env
    create_test_checkpoint
    run_fallback generate > /dev/null 2>&1
    run_fallback clean > /dev/null 2>&1
    local has_files=0
    [ -f "$TEST_DIR/.aidev/state/fallback/last-checkpoint.md" ] && has_files=1
    assert_equals "0" "$has_files" "Clean deve remover arquivos de fallback"
}

test_fallback_clean_empty() {
    setup_aidev_env
    local result=$(run_fallback clean)
    assert_contains "$result" "Nenhum" "Clean sem artefatos deve informar"
}

# ============================================================================
# TESTES: fallback help
# ============================================================================

test_fallback_no_args_shows_help() {
    setup_aidev_env
    local result=$(run_fallback)
    assert_contains "$result" "fallback" "Sem args deve mostrar uso do comando"
    assert_contains "$result" "generate" "Help deve mostrar subcomando generate"
}

# MAIN
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  FALLBACK COMMAND TEST SUITE - Sprint 5                        ║"
echo "║  AI Dev Superpowers v4.0.0 - Feature 5.3.3                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Fallback Command Tests" \
    test_fallback_generate_basic \
    test_fallback_generate_creates_files \
    test_fallback_generate_checkpoint_content \
    test_fallback_generate_without_checkpoint \
    test_fallback_show_no_artifacts \
    test_fallback_show_with_artifacts \
    test_fallback_clean_removes_files \
    test_fallback_clean_empty \
    test_fallback_no_args_shows_help

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
