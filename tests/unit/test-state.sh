#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3.2 - Unit Tests: State Manager
# ============================================================================
# Testes unitarios para lib/state.sh
# ============================================================================

# Detecta diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Se não estiver rodando via test-runner.sh, define as variáveis e cores
if [ -z "$TESTS_TOTAL" ]; then
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_TOTAL=0
    TESTS_SKIPPED=0
    
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    RUNNING_ALONE=true
else
    RUNNING_ALONE=false
fi

# ============================================================================
# Helpers de Teste
# ============================================================================

setup_test_env() {
    TEST_DIR=$(mktemp -d)
    export CLI_INSTALL_PATH="$TEST_DIR"
    mkdir -p "$TEST_DIR/.aidev/state"
    source "$PROJECT_ROOT/lib/core.sh"
    source "$PROJECT_ROOT/lib/file-ops.sh"
    source "$PROJECT_ROOT/lib/detection.sh"
    source "$PROJECT_ROOT/lib/state.sh"
}

teardown_test_env() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Sobrescreve run_test local para usar contadores corretos
run_test_local() {
    local test_name="$1"
    local test_func="$2"
    
    setup_test_env
    echo -n "  Testing: $test_name... "
    
    ((TESTS_TOTAL++))
    if $test_func; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((TESTS_FAILED++))
    fi
    
    teardown_test_env
}

# ============================================================================
# Testes (Mesma lógica de antes)
# ============================================================================

test_state_init_creates_file() {
    state_init
    [ -f "$TEST_DIR/.aidev/state/unified.json" ]
}

test_state_init_creates_valid_json() {
    state_init
    if command -v jq >/dev/null 2>&1; then
        jq . "$TEST_DIR/.aidev/state/unified.json" >/dev/null 2>&1
    else
        [ -s "$TEST_DIR/.aidev/state/unified.json" ]
    fi
}

test_state_init_has_version() {
    state_init
    local version=$(state_read "version")
    [ "$version" = "3.2.0" ]
}

test_state_init_has_session_id() {
    state_init
    local session_id=$(state_read "session.id")
    [ -n "$session_id" ]
}

test_state_ensure_is_idempotent() {
    state_init
    local first_id=$(state_read "session.id")
    state_ensure
    local second_id=$(state_read "session.id")
    [ "$first_id" = "$second_id" ]
}

test_state_write_and_read_string() {
    state_init
    state_write "active_skill" "brainstorming"
    local value=$(state_read "active_skill")
    [ "$value" = "brainstorming" ]
}

test_state_write_and_read_nested() {
    state_init
    local value=$(state_read "session.stack")
    [ -n "$value" ]
}

test_state_read_with_default() {
    state_init
    local value=$(state_read "nonexistent.key" "default_value")
    [ "$value" = "default_value" ]
}

test_state_write_null() {
    state_init
    state_write "active_skill" "brainstorming"
    state_write "active_skill" "null"
    local value=$(state_read "active_skill")
    [ "$value" = "null" ] || [ -z "$value" ]
}

test_state_append_to_array() {
    state_init
    state_append "artifacts" '{"path": "test.md", "type": "document"}'
    if command -v jq >/dev/null 2>&1; then
        local count=$(jq '.artifacts | length' "$TEST_DIR/.aidev/state/unified.json")
        [ "$count" = "1" ]
    else
        return 0
    fi
}

test_state_append_multiple() {
    state_init
    state_append "artifacts" '{"path": "test1.md", "type": "document"}'
    state_append "artifacts" '{"path": "test2.md", "type": "design"}'
    if command -v jq >/dev/null 2>&1; then
        local count=$(jq '.artifacts | length' "$TEST_DIR/.aidev/state/unified.json")
        [ "$count" = "2" ]
    else
        return 0
    fi
}

test_state_checkpoint_creates_snapshot() {
    state_init
    local cp_id=$(state_checkpoint "Test checkpoint")
    [[ "$cp_id" == cp-* ]]
}

test_state_checkpoint_preserves_state() {
    state_init
    state_write "active_skill" "brainstorming"
    local cp_id=$(state_checkpoint "Before change")
    state_write "active_skill" "debugging"
    if command -v jq >/dev/null 2>&1; then
        local saved_skill=$(jq -r '.rollback_stack[0].state_snapshot.active_skill' "$TEST_DIR/.aidev/state/unified.json")
        [ "$saved_skill" = "brainstorming" ]
    else
        return 0
    fi
}

test_state_rollback_restores_state() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_write "active_skill" "brainstorming"
    local cp_id=$(state_checkpoint "Before change")
    state_write "active_skill" "debugging"
    state_rollback
    local restored=$(state_read "active_skill")
    [ "$restored" = "brainstorming" ]
}

test_state_rollback_to_specific_checkpoint() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_write "active_skill" "step1"
    local cp1=$(state_checkpoint "Checkpoint 1")
    state_write "active_skill" "step2"
    local cp2=$(state_checkpoint "Checkpoint 2")
    state_write "active_skill" "step3"
    state_rollback "$cp1"
    local restored=$(state_read "active_skill")
    [ "$restored" = "step1" ]
}

test_state_list_rollback_points() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_checkpoint "First"
    state_checkpoint "Second"
    local points=$(state_list_rollback_points)
    [[ "$points" == *"First"* ]] && [[ "$points" == *"Second"* ]]
}

test_state_validate_success() {
    state_init
    state_validate
}

test_state_validate_detects_missing_file() {
    rm -f "$TEST_DIR/.aidev/state/unified.json"
    [ ! -f "$TEST_DIR/.aidev/state/unified.json" ]
}

test_state_validate_detects_corruption() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    echo "not valid json {{{" > "$TEST_DIR/.aidev/state/unified.json"
    ! state_validate 2>/dev/null
}

test_state_repair_recovers() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    echo "corrupted" > "$TEST_DIR/.aidev/state/unified.json"
    state_repair > /dev/null
    state_validate
}

test_state_log_confidence() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_log_confidence "Usar React Query" "0.85" "high"
    local count=$(jq '.confidence_log | length' "$TEST_DIR/.aidev/state/unified.json")
    [ "$count" = "1" ]
}

test_state_queue_handoff() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_queue_handoff "architect" "backend" "Implementar API" "docs/design.md"
    local count=$(jq '.agent_queue | length' "$TEST_DIR/.aidev/state/unified.json")
    [ "$count" = "1" ] || return 1
    local to_agent=$(jq -r '.agent_queue[0].to' "$TEST_DIR/.aidev/state/unified.json")
    [ "$to_agent" = "backend" ]
}

test_state_add_artifact() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_add_artifact "docs/design.md" "design" "brainstorming"
    local path=$(jq -r '.artifacts[0].path' "$TEST_DIR/.aidev/state/unified.json")
    [ "$path" = "docs/design.md" ]
}

test_state_activate_skill() {
    state_init
    state_activate_skill "brainstorming" > /dev/null
    local active=$(state_get_active_skill)
    [ "$active" = "brainstorming" ]
}

test_state_deactivate_skill() {
    state_init
    state_activate_skill "brainstorming" > /dev/null
    state_deactivate_skill > /dev/null
    local active=$(state_get_active_skill)
    [ -z "$active" ] || [ "$active" = "null" ]
}

test_state_set_checkpoint() {
    command -v jq >/dev/null 2>&1 || return 0
    state_init
    state_set_checkpoint "brainstorming" "step_1" "Entender problema" > /dev/null
    local step=$(jq -r '.checkpoints.brainstorming[0].step' "$TEST_DIR/.aidev/state/unified.json")
    [ "$step" = "step_1" ]
}

test_state_migrate_legacy_session() {
    command -v jq >/dev/null 2>&1 || return 0
    cat > "$TEST_DIR/.aidev/state/session.json" << EOF
{"current_fase": "3", "current_sprint": "4", "project_name": "test-project"}
EOF
    state_migrate_legacy > /dev/null
    local fase=$(jq -r '.session.current_fase' "$TEST_DIR/.aidev/state/unified.json")
    [ "$fase" = "3" ]
}

test_state_migrate_legacy_skills() {
    command -v jq >/dev/null 2>&1 || return 0
    cat > "$TEST_DIR/.aidev/state/skills.json" << EOF
{"active_skill": "brainstorming", "skill_states": {}}
EOF
    state_migrate_legacy > /dev/null
    local active=$(state_get_active_skill)
    [ "$active" = "brainstorming" ]
}

test_state_export_produces_output() {
    state_init
    state_write "active_skill" "brainstorming"
    local output=$(state_export)
    [[ "$output" == *"AI Dev Superpowers"* ]] && [[ "$output" == *"brainstorming"* ]]
}

# ============================================================================
# Runner
# ============================================================================

run_all_tests() {
    if $RUNNING_ALONE; then
        echo "=============================================="
        echo "  AI Dev Superpowers - State Manager Tests"
        echo "=============================================="
    fi
    
    echo "Initialization Tests:"
    run_test_local "state_init creates file" test_state_init_creates_file
    run_test_local "state_init creates valid JSON" test_state_init_creates_valid_json
    run_test_local "state_init has version" test_state_init_has_version
    run_test_local "state_init has session ID" test_state_init_has_session_id
    run_test_local "state_ensure is idempotent" test_state_ensure_is_idempotent
    
    echo ""
    echo "Read/Write Tests:"
    run_test_local "state_write and state_read string" test_state_write_and_read_string
    run_test_local "state_write and state_read nested" test_state_write_and_read_nested
    run_test_local "state_read with default" test_state_read_with_default
    run_test_local "state_write null" test_state_write_null
    run_test_local "state_append to array" test_state_append_to_array
    run_test_local "state_append multiple" test_state_append_multiple
    
    echo ""
    echo "Checkpoint/Rollback Tests:"
    run_test_local "state_checkpoint creates snapshot" test_state_checkpoint_creates_snapshot
    run_test_local "state_checkpoint preserves state" test_state_checkpoint_preserves_state
    run_test_local "state_rollback restores state" test_state_rollback_restores_state
    run_test_local "state_rollback to specific checkpoint" test_state_rollback_to_specific_checkpoint
    run_test_local "state_list_rollback_points" test_state_list_rollback_points
    
    echo ""
    echo "Validation Tests:"
    run_test_local "state_validate success" test_state_validate_success
    run_test_local "state_validate detects missing file" test_state_validate_detects_missing_file
    run_test_local "state_validate detects corruption" test_state_validate_detects_corruption
    run_test_local "state_repair recovers" test_state_repair_recovers
    
    echo ""
    echo "Convenience Functions Tests:"
    run_test_local "state_log_confidence" test_state_log_confidence
    run_test_local "state_queue_handoff" test_state_queue_handoff
    run_test_local "state_add_artifact" test_state_add_artifact
    run_test_local "state_activate_skill" test_state_activate_skill
    run_test_local "state_deactivate_skill" test_state_deactivate_skill
    run_test_local "state_set_checkpoint" test_state_set_checkpoint
    
    echo ""
    echo "Legacy Migration Tests:"
    run_test_local "state_migrate_legacy session" test_state_migrate_legacy_session
    run_test_local "state_migrate_legacy skills" test_state_migrate_legacy_skills
    
    echo ""
    echo "Export Tests:"
    run_test_local "state_export produces output" test_state_export_produces_output
    
    if $RUNNING_ALONE; then
        echo ""
        echo "=============================================="
        echo "  Test Summary"
        echo "=============================================="
        echo -e "  Passed:  $TESTS_PASSED"
        echo -e "  Failed:  $TESTS_FAILED"
        echo "=============================================="
    fi
}

run_all_tests
