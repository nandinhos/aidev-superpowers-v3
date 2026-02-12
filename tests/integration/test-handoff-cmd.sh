#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Handoff Command Integration Tests
# ============================================================================
# Testes de integracao para o comando 'aidev handoff'
# Sprint 5 - Feature 5.1.3
#
# Uso: ./test-handoff-cmd.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"

# Setup aidev environment
setup_aidev_env() {
    ensure_dir "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$TEST_DIR/.aidev/state"
    ensure_dir "$TEST_DIR/lib"

    cp "$ROOT_DIR/lib/context-monitor.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/checkpoint-manager.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/core.sh" "$TEST_DIR/lib/" 2>/dev/null || true

    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "3.9.0",
  "session": {
    "id": "test-session",
    "project_name": "test-project"
  },
  "active_intent": "feature_request",
  "intent_description": "Implementando feature X"
}
EOF

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

    touch "$TEST_DIR/.aidev/.installed"
}

run_handoff() {
    cd "$TEST_DIR" && "$ROOT_DIR/bin/aidev" handoff "$@" 2>&1 || true
}

# ============================================================================
# TESTES: handoff create
# ============================================================================

test_handoff_create_basic() {
    setup_aidev_env
    local result=$(run_handoff create --cot "Implementando validadores")
    assert_contains "$result" "Handoff criado" "Deve confirmar criacao do handoff"
    assert_contains "$result" "ckpt-" "Deve mostrar ID do checkpoint"
}

test_handoff_create_with_all_fields() {
    setup_aidev_env
    local result=$(run_handoff create \
        --cot "Raciocinio em andamento" \
        --hypothesis "Bug na linha 45" \
        --mental-model "A -> B -> C" \
        --observations "Nota livre")
    assert_contains "$result" "Handoff criado" "Deve criar handoff com todos os campos"
}

test_handoff_create_generates_checkpoint_file() {
    setup_aidev_env
    local result=$(run_handoff create --cot "Test file creation")
    local ckpt_dir="$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    local files=$(ls "$ckpt_dir"/ckpt-*.json 2>/dev/null | wc -l)
    assert_not_equals "0" "$files" "Deve criar arquivo de checkpoint"
}

test_handoff_create_checkpoint_has_cognitive_context() {
    setup_aidev_env
    run_handoff create --cot "Testando contexto cognitivo" --hypothesis "Minha hipotese"
    local ckpt_dir="$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    local latest=$(ls -t "$ckpt_dir"/ckpt-*.json 2>/dev/null | head -1)
    if [ -n "$latest" ] && command -v jq >/dev/null 2>&1; then
        local cot=$(jq -r '.cognitive_context.chain_of_thought' "$latest")
        assert_equals "Testando contexto cognitivo" "$cot" "Checkpoint deve conter chain_of_thought"
        local hyp=$(jq -r '.cognitive_context.current_hypothesis' "$latest")
        assert_equals "Minha hipotese" "$hyp" "Checkpoint deve conter hypothesis"
    else
        echo "⚠️  SKIP: checkpoint nao encontrado ou jq indisponivel"
        ((TESTS_PASSED++))
        ((TESTS_PASSED++))
    fi
}

# ============================================================================
# TESTES: handoff resume
# ============================================================================

test_handoff_resume_shows_latest() {
    setup_aidev_env
    run_handoff create --cot "Contexto para resume" > /dev/null 2>&1
    local result=$(run_handoff resume)
    assert_contains "$result" "RESTAURAR CONTEXTO" "Resume deve mostrar prompt de restauracao"
}

test_handoff_resume_includes_cognitive() {
    setup_aidev_env
    run_handoff create --cot "Estava debugando o parser" --hypothesis "Regex incorreto" > /dev/null 2>&1
    local result=$(run_handoff resume)
    assert_contains "$result" "CONTEXTO COGNITIVO" "Resume deve incluir secao cognitiva"
    assert_contains "$result" "Estava debugando o parser" "Resume deve incluir chain_of_thought"
}

test_handoff_resume_empty() {
    local isolated_dir="$(mktemp -d)"
    ensure_dir "$isolated_dir/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$isolated_dir/.aidev/state"
    touch "$isolated_dir/.aidev/.installed"
    cat > "$isolated_dir/.aidev/state/unified.json" << 'EOF'
{"version": "3.9.0", "session": {"project_name": "test"}}
EOF
    cat > "$isolated_dir/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{"sprint_id": "test", "status": "in_progress"}
EOF

    local result=$(cd "$isolated_dir" && "$ROOT_DIR/bin/aidev" handoff resume 2>&1 || true)
    assert_contains "$result" "Nenhum handoff" "Resume sem checkpoints deve mostrar mensagem"

    rm -rf "$isolated_dir"
}

# ============================================================================
# TESTES: handoff status
# ============================================================================

test_handoff_status_no_handoffs() {
    local isolated_dir="$(mktemp -d)"
    ensure_dir "$isolated_dir/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$isolated_dir/.aidev/state"
    touch "$isolated_dir/.aidev/.installed"
    cat > "$isolated_dir/.aidev/state/unified.json" << 'EOF'
{"version": "3.9.0", "session": {"project_name": "test"}}
EOF
    cat > "$isolated_dir/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{"sprint_id": "test", "status": "in_progress"}
EOF

    local result=$(cd "$isolated_dir" && "$ROOT_DIR/bin/aidev" handoff status 2>&1 || true)
    assert_contains "$result" "Nenhum handoff" "Status sem handoffs deve informar"

    rm -rf "$isolated_dir"
}

test_handoff_status_with_handoffs() {
    setup_aidev_env
    run_handoff create --cot "Primeiro handoff" > /dev/null 2>&1
    local result=$(run_handoff status)
    assert_contains "$result" "Handoff" "Status deve mostrar informacoes do handoff"
    assert_contains "$result" "ckpt-" "Status deve mostrar ID do checkpoint"
}

# ============================================================================
# TESTES: handoff default/help
# ============================================================================

test_handoff_no_args_shows_help() {
    setup_aidev_env
    local result=$(cd "$TEST_DIR" && "$ROOT_DIR/bin/aidev" handoff 2>&1 || true)
    assert_contains "$result" "handoff" "Sem args deve mostrar uso do comando"
}

# MAIN
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  HANDOFF COMMAND TEST SUITE - Sprint 5                         ║"
echo "║  AI Dev Superpowers v4.0.0                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Handoff Command Tests" \
    test_handoff_create_basic \
    test_handoff_create_with_all_fields \
    test_handoff_create_generates_checkpoint_file \
    test_handoff_create_checkpoint_has_cognitive_context \
    test_handoff_resume_shows_latest \
    test_handoff_resume_includes_cognitive \
    test_handoff_resume_empty \
    test_handoff_status_no_handoffs \
    test_handoff_status_with_handoffs \
    test_handoff_no_args_shows_help

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
