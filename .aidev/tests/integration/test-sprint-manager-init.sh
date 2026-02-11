#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Sprint Manager Integration Tests
# ============================================================================
# Testes de integracao para sprint-manager na inicializacao do agente
#
# Uso: ./test-sprint-manager-init.sh
# ============================================================================

# Setup test environment
TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

# Load test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
source "$ROOT_DIR/lib/core.sh"

# Setup completo do projeto de teste
setup_test_project() {
    # Estrutura de diretorios
    ensure_dir "$TEST_DIR/.aidev/state/sprints/current"
    ensure_dir "$TEST_DIR/.aidev/state/sprints/history"
    ensure_dir "$TEST_DIR/.aidev/agents"
    ensure_dir "$TEST_DIR/.aidev/skills"

    # sprint-status.json
    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{
  "sprint_id": "sprint-2-knowledge-management",
  "sprint_name": "Sprint 2: Knowledge Management",
  "status": "in_progress",
  "overall_progress": {
    "total_tasks": 5,
    "completed": 5,
    "in_progress": 0,
    "pending": 0,
    "blocked": 0,
    "percentage": 100
  },
  "session_context": {
    "checkpoints_created": 7,
    "sessions_count": 2,
    "tokens_used_in_sprint": 12500
  },
  "next_action": {
    "task_id": "task-2.3-backlog",
    "description": "Iniciar sistema de backlog",
    "estimated_tokens": 3500
  }
}
EOF

    # unified.json
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "3.8.0",
  "session": {
    "id": "test-session",
    "started_at": "2026-02-11T10:00:00Z",
    "last_activity": "2026-02-11T12:00:00Z",
    "project_name": "test-project",
    "stack": "generic",
    "maturity": "brownfield",
    "current_fase": "3",
    "current_sprint": "4",
    "language": "pt-BR"
  },
  "active_skill": "release-management",
  "active_agent": null,
  "active_intent": "release",
  "intent_description": "Preparar release patch"
}
EOF

    # session.json (legado)
    cat > "$TEST_DIR/.aidev/state/session.json" << 'EOF'
{
  "current_fase": "3",
  "current_sprint": "4",
  "current_stack": "generic",
  "language": "pt-BR",
  "version": "3.8.0"
}
EOF

    # Agentes e skills mockados
    echo "# Orchestrator Agent" > "$TEST_DIR/.aidev/agents/orchestrator.md"
    echo "# Backend Agent" > "$TEST_DIR/.aidev/agents/backend.md"
    mkdir -p "$TEST_DIR/.aidev/skills/brainstorming"
    mkdir -p "$TEST_DIR/.aidev/skills/writing-plans"
}

# ============================================================================
# TESTS: Integracao sprint_sync_to_unified()
# ============================================================================

test_integration_sync_creates_sprint_context_in_unified() {
    # Arrange
    setup_test_project
    source "$ROOT_DIR/lib/sprint-manager.sh"

    # Act
    sprint_sync_to_unified "$TEST_DIR"

    # Assert
    local unified_file="$TEST_DIR/.aidev/state/unified.json"
    assert_file_exists "$unified_file" "unified.json existe"

    local sprint_id=$(jq -r '.sprint_context.sprint_id' "$unified_file")
    assert_equals "$sprint_id" "sprint-2-knowledge-management" "sprint_context.sprint_id presente"

    local progress=$(jq -r '.sprint_context.progress_percentage' "$unified_file")
    assert_equals "$progress" "100" "sprint_context.progress_percentage presente"

    local tokens=$(jq -r '.sprint_context.session_metrics.tokens_used' "$unified_file")
    assert_equals "$tokens" "12500" "sprint_context.session_metrics.tokens_used presente"
}

test_integration_sync_preserves_existing_unified_fields() {
    # Arrange
    setup_test_project
    source "$ROOT_DIR/lib/sprint-manager.sh"

    # Act
    sprint_sync_to_unified "$TEST_DIR"

    # Assert
    local unified_file="$TEST_DIR/.aidev/state/unified.json"

    local active_skill=$(jq -r '.active_skill' "$unified_file")
    assert_equals "$active_skill" "release-management" "Preserva active_skill"

    local active_intent=$(jq -r '.active_intent' "$unified_file")
    assert_equals "$active_intent" "release" "Preserva active_intent"

    local fase=$(jq -r '.session.current_fase' "$unified_file")
    assert_equals "$fase" "3" "Preserva session.current_fase"
}

# ============================================================================
# TESTS: Integracao cmd_agent() (simulacao)
# ============================================================================

test_integration_cmd_agent_context_includes_sprint() {
    # Arrange
    setup_test_project
    source "$ROOT_DIR/lib/sprint-manager.sh"

    # Simula parte do cmd_agent() que gera contexto de sprint
    sprint_sync_to_unified "$TEST_DIR"

    local unified_file="$TEST_DIR/.aidev/state/unified.json"
    local sprint_context=""

    if [ -f "$unified_file" ] && command -v jq >/dev/null 2>&1; then
        local sprint_id=$(jq -r '.sprint_context.sprint_id // "N/A"' "$unified_file")
        local sprint_status=$(jq -r '.sprint_context.status // "N/A"' "$unified_file")
        local completed=$(jq -r '.sprint_context.completed_tasks // 0' "$unified_file")
        local total=$(jq -r '.sprint_context.total_tasks // 0' "$unified_file")
        local progress=$(jq -r '.sprint_context.progress_percentage // 0' "$unified_file")
        local next_desc=$(jq -r '.sprint_context.next_action.description // "Nenhuma ação pendente"' "$unified_file")

        if [ "$sprint_id" != "N/A" ]; then
            sprint_context="
CONTEXTO DA SPRINT:
- Sprint ID: $sprint_id
- Status: $sprint_status
- Progresso: $completed/$total tarefas ($progress%)
- Próxima Ação: $next_desc
"
        fi
    fi

    # Assert
    assert_contains "$sprint_context" "CONTEXTO DA SPRINT:" "Contexto tem header"
    assert_contains "$sprint_context" "sprint-2-knowledge-management" "Contexto tem sprint_id"
    assert_contains "$sprint_context" "in_progress" "Contexto tem status"
    assert_contains "$sprint_context" "5/5 tarefas (100%)" "Contexto tem progresso"
    assert_contains "$sprint_context" "Iniciar sistema de backlog" "Contexto tem proxima acao"
}

test_integration_cmd_agent_context_empty_if_no_sprint() {
    # Arrange
    setup_test_project
    rm -f "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json"

    source "$ROOT_DIR/lib/sprint-manager.sh"

    # Simula cmd_agent()
    sprint_sync_to_unified "$TEST_DIR"

    local unified_file="$TEST_DIR/.aidev/state/unified.json"
    local sprint_context=""

    if [ -f "$unified_file" ] && command -v jq >/dev/null 2>&1; then
        local sprint_id=$(jq -r '.sprint_context.sprint_id // "N/A"' "$unified_file")

        if [ "$sprint_id" != "N/A" ]; then
            sprint_context="CONTEXTO DA SPRINT"
        fi
    fi

    # Assert
    assert_equals "$sprint_context" "" "Contexto vazio se nao ha sprint"
}

# ============================================================================
# TESTS: Integracao state_sync_legacy_session()
# ============================================================================

test_integration_legacy_session_sync_updates_session_json() {
    # Arrange
    setup_test_project
    source "$ROOT_DIR/lib/state.sh"

    # Act
    state_sync_legacy_session

    # Assert
    local session_file="$TEST_DIR/.aidev/state/session.json"
    assert_file_exists "$session_file" "session.json existe"

    local fase=$(jq -r '.current_fase' "$session_file")
    assert_equals "$fase" "3" "session.json sincronizado com unified.json (fase)"

    local agent_mode=$(jq -r '.agent_mode_active' "$session_file")
    assert_equals "$agent_mode" "true" "session.json tem agent_mode_active=true"

    local last_activation=$(jq -r '.last_activation' "$session_file")
    assert_not_equals "$last_activation" "null" "session.json tem last_activation atualizado"
}

# ============================================================================
# TESTS: Dashboard Rendering
# ============================================================================

test_integration_dashboard_renders_complete_output() {
    # Arrange
    setup_test_project
    source "$ROOT_DIR/lib/sprint-manager.sh"

    # Act
    local output=$(sprint_render_summary "$TEST_DIR")

    # Assert
    assert_contains "$output" "Sprint Atual:" "Dashboard tem header"
    assert_contains "$output" "Sprint 2: Knowledge Management" "Dashboard tem nome"
    assert_contains "$output" "Status:" "Dashboard tem status"
    assert_contains "$output" "Progresso:" "Dashboard tem progresso"
    assert_contains "$output" "5/5 concluídas" "Dashboard tem contador de tarefas"
    assert_contains "$output" "Próxima Ação:" "Dashboard tem proxima acao"
    assert_contains "$output" "Iniciar sistema de backlog" "Dashboard tem descricao da acao"
}

# ============================================================================
# RUN TESTS
# ============================================================================

run_test_suite "Sprint Manager Integration" \
    test_integration_sync_creates_sprint_context_in_unified \
    test_integration_sync_preserves_existing_unified_fields \
    test_integration_cmd_agent_context_includes_sprint \
    test_integration_cmd_agent_context_empty_if_no_sprint \
    test_integration_legacy_session_sync_updates_session_json \
    test_integration_dashboard_renders_complete_output

# Cleanup
rm -rf "$TEST_DIR"
