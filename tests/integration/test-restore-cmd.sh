#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Restore Command Integration Tests
# ============================================================================
# Testes de integracao para o comando 'aidev restore'
# TDD: RED phase
#
# Uso: ./test-restore-cmd.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"

# Setup aidev environment
setup_aidev_env() {
    # Create .aidev structure
    ensure_dir "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$TEST_DIR/.aidev/state"
    ensure_dir "$TEST_DIR/lib"
    
    # Copy essential files
    cp "$ROOT_DIR/lib/context-monitor.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/checkpoint-manager.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    cp "$ROOT_DIR/lib/core.sh" "$TEST_DIR/lib/" 2>/dev/null || true
    
    # Create mock unified.json
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "3.9.0",
  "session": {
    "id": "test-session",
    "project_name": "test-project"
  }
}
EOF
    
    # Create mock sprint-status.json
    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{
  "sprint_id": "sprint-test",
  "sprint_name": "Test Sprint",
  "status": "in_progress",
  "current_task": "task-1"
}
EOF
    
    # Create .aidev marker
    touch "$TEST_DIR/.aidev/.installed"
}

# Create test checkpoints
create_test_checkpoints() {
    source "$ROOT_DIR/lib/checkpoint-manager.sh" 2>/dev/null || true
    
    # Create checkpoint 1
    local ckpt1_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-001.json"
    cat > "$ckpt1_file" << 'EOF'
{
  "checkpoint_id": "ckpt-test-001",
  "trigger": "manual",
  "description": "Primeiro checkpoint de teste",
  "created_at": "2026-02-11T10:00:00Z",
  "state_snapshot": {
    "session": {
      "project_name": "test-project"
    }
  },
  "sprint_snapshot": {
    "sprint_id": "sprint-test",
    "current_task": "task-1"
  }
}
EOF
    
    # Create checkpoint 2 (more recent)
    sleep 1
    local ckpt2_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/ckpt-test-002.json"
    cat > "$ckpt2_file" << 'EOF'
{
  "checkpoint_id": "ckpt-test-002",
  "trigger": "auto_checkpoint",
  "description": "Segundo checkpoint de teste",
  "created_at": "2026-02-11T11:00:00Z",
  "state_snapshot": {
    "session": {
      "project_name": "test-project"
    }
  },
  "sprint_snapshot": {
    "sprint_id": "sprint-test",
    "current_task": "task-2"
  }
}
EOF
}

# Run aidev restore command
run_restore() {
    local args="$1"
    cd "$TEST_DIR" && "$ROOT_DIR/bin/aidev" restore $args 2>&1 || true
}

# ============================================================================
# TESTES: List checkpoints
# ============================================================================

test_restore_list_empty() {
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
    
    local result=$(cd "$isolated_dir" && "$ROOT_DIR/bin/aidev" restore --list 2>&1 || true)
    
    assert_contains "$result" "Nenhum checkpoint" "List vazio deve mostrar mensagem apropriada"
    
    rm -rf "$isolated_dir"
}

test_restore_list_with_checkpoints() {
    setup_aidev_env
    create_test_checkpoints
    
    local result=$(run_restore "--list")
    
    assert_contains "$result" "Checkpoints Disponiveis" "Deve mostrar header"
    assert_contains "$result" "ckpt-test-001" "Deve listar checkpoint 1"
    assert_contains "$result" "ckpt-test-002" "Deve listar checkpoint 2"
    assert_contains "$result" "Total: 2" "Deve mostrar total correto"
}

test_restore_list_shows_details() {
    setup_aidev_env
    create_test_checkpoints
    
    local result=$(run_restore "--list")
    
    assert_contains "$result" "manual" "Deve mostrar trigger manual"
    assert_contains "$result" "auto_checkpoint" "Deve mostrar trigger auto"
    assert_contains "$result" "Primeiro checkpoint" "Deve mostrar descricao"
}

# ============================================================================
# TESTES: Restore latest
# ============================================================================

test_restore_latest_success() {
    setup_aidev_env
    create_test_checkpoints
    
    local result=$(run_restore "--latest")
    
    assert_contains "$result" "RESTAURAR CONTEXTO" "Deve mostrar titulo do prompt"
    assert_contains "$result" "ckpt-test-002" "Deve restaurar checkpoint mais recente"
    assert_contains "$result" "test-project" "Deve incluir nome do projeto"
}

test_restore_latest_empty() {
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
    
    local result=$(cd "$isolated_dir" && "$ROOT_DIR/bin/aidev" restore --latest 2>&1 || true)
    
    assert_contains "$result" "Nenhum checkpoint encontrado" "Latest sem checkpoints deve mostrar erro"
    
    rm -rf "$isolated_dir"
}

# ============================================================================
# TESTES: Restore by ID
# ============================================================================

test_restore_by_id_success() {
    setup_aidev_env
    create_test_checkpoints
    
    local result=$(run_restore "ckpt-test-001")
    
    assert_contains "$result" "RESTAURAR CONTEXTO" "Deve mostrar titulo"
    assert_contains "$result" "ckpt-test-001" "Deve restaurar checkpoint especificado"
}

test_restore_by_id_not_found() {
    setup_aidev_env
    create_test_checkpoints
    
    local result=$(run_restore "ckpt-inexistente")
    
    assert_contains "$result" "nao encontrado" "ID inexistente deve mostrar erro"
    assert_contains "$result" "aidev restore --list" "Deve sugerir listar checkpoints"
}

# ============================================================================
# TESTES: Default behavior
# ============================================================================

test_restore_default_is_list() {
    setup_aidev_env
    create_test_checkpoints
    
    # Call without subcommand
    local result=$(run_restore "")
    
    assert_contains "$result" "Checkpoints Disponiveis" "Default deve ser list"
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  RESTORE COMMAND TEST SUITE - TDD RED PHASE                    ║"
echo "║  AI Dev Superpowers v3.9.0                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Restore Command Tests" \
    test_restore_list_empty \
    test_restore_list_with_checkpoints \
    test_restore_list_shows_details \
    test_restore_latest_success \
    test_restore_latest_empty \
    test_restore_by_id_success \
    test_restore_by_id_not_found \
    test_restore_default_is_list

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
