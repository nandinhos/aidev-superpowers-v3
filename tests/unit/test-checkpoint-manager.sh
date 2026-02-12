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
source "$ROOT_DIR/lib/fallback-generator.sh"

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

# ============================================================================
# TESTES: ckpt_create com cognitive_context (Sprint 5 - Feature 5.1)
# ============================================================================

test_ckpt_create_with_cognitive_context() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test cognitive" \
        "Estou implementando validadores" \
        "O bug esta na funcao parse" \
        "Fluxo: input -> parse -> validate -> output")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local cot=$(jq -r '.cognitive_context.chain_of_thought' "$ckpt_file")
        assert_equals "Estou implementando validadores" "$cot" "chain_of_thought deve estar presente"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_cognitive_hypothesis() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test hypothesis" \
        "Raciocinio em andamento" \
        "Bug na linha 45 de validators.sh" \
        "Modelo mental do fluxo")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local hyp=$(jq -r '.cognitive_context.current_hypothesis' "$ckpt_file")
        assert_equals "Bug na linha 45 de validators.sh" "$hyp" "current_hypothesis deve estar presente"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_cognitive_mental_model() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test mental model" \
        "CoT aqui" \
        "Hipotese aqui" \
        "A -> B -> C, estou no passo B")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local mm=$(jq -r '.cognitive_context.mental_model' "$ckpt_file")
        assert_equals "A -> B -> C, estou no passo B" "$mm" "mental_model deve estar presente"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_without_cognitive_context_backward_compat() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Sem contexto cognitivo")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local trigger=$(jq -r '.trigger' "$ckpt_file")
        assert_equals "manual" "$trigger" "Checkpoint sem cognitive_context deve funcionar normalmente"
        local has_cognitive=$(jq 'has("cognitive_context")' "$ckpt_file")
        assert_equals "true" "$has_cognitive" "cognitive_context deve existir mesmo vazio"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_cognitive_empty_defaults() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Defaults")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local cot=$(jq -r '.cognitive_context.chain_of_thought' "$ckpt_file")
        local hyp=$(jq -r '.cognitive_context.current_hypothesis' "$ckpt_file")
        local mm=$(jq -r '.cognitive_context.mental_model' "$ckpt_file")
        assert_equals "" "$cot" "chain_of_thought default deve ser vazio"
        assert_equals "" "$hyp" "current_hypothesis default deve ser vazio"
        assert_equals "" "$mm" "mental_model default deve ser vazio"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_cognitive_observations_field() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test obs" \
        "CoT" "Hipotese" "Modelo" "Nota livre do desenvolvedor")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local obs=$(jq -r '.cognitive_context.observations' "$ckpt_file")
        assert_equals "Nota livre do desenvolvedor" "$obs" "observations deve estar presente"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_cognitive_confidence_field() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Defaults")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local has_confidence=$(jq '.cognitive_context | has("confidence")' "$ckpt_file")
        assert_equals "true" "$has_confidence" "cognitive_context deve ter campo confidence"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

# ============================================================================
# TESTES: ckpt_generate_restore_prompt com cognitive_context (Sprint 5 - 5.1.2)
# ============================================================================

test_restore_prompt_includes_cognitive_section() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Test cognitive prompt" \
        "Implementando feature X" "Bug na funcao Y" "Fluxo A->B->C")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        assert_contains "$prompt" "CONTEXTO COGNITIVO" "Prompt deve conter secao CONTEXTO COGNITIVO"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_restore_prompt_includes_chain_of_thought() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "CoT test" \
        "Estava analisando o modulo de cache" "" "")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        assert_contains "$prompt" "Estava analisando o modulo de cache" "Prompt deve incluir chain_of_thought"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_restore_prompt_includes_hypothesis() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Hyp test" \
        "" "O erro esta no parser de JSON" "")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        assert_contains "$prompt" "O erro esta no parser de JSON" "Prompt deve incluir hipotese"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_restore_prompt_includes_mental_model() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "MM test" \
        "" "" "Input -> Validate -> Transform -> Output")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        assert_contains "$prompt" "Input -> Validate -> Transform -> Output" "Prompt deve incluir modelo mental"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_restore_prompt_skips_empty_cognitive() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "No cognitive")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local prompt=$(ckpt_generate_restore_prompt "$ckpt_file")
        # Quando nao ha contexto cognitivo preenchido, a secao nao deve aparecer
        local has_section=0
        echo "$prompt" | grep -q "Raciocinio:" && has_section=1
        assert_equals "0" "$has_section" "Prompt sem cognitive preenchido nao deve mostrar raciocinio"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ckpt_create_cognitive_decisions_pending() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Defaults")
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    if command -v jq >/dev/null 2>&1; then
        local has_decisions=$(jq '.cognitive_context | has("decisions_pending")' "$ckpt_file")
        assert_equals "true" "$has_decisions" "cognitive_context deve ter campo decisions_pending"
        local type=$(jq -r '.cognitive_context.decisions_pending | type' "$ckpt_file")
        assert_equals "array" "$type" "decisions_pending deve ser um array"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

# ============================================================================
# TESTES: ckpt_create com fallback generation (Sprint 5 - Feature 5.3.2)
# ============================================================================

test_ckpt_create_generates_fallback_when_enabled() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    export CKPT_GENERATE_FALLBACK="true"
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Fallback test")
    local fallback_dir="$TEST_DIR/.aidev/state/fallback"
    assert_file_exists "$fallback_dir/last-checkpoint.md" "Deve gerar last-checkpoint.md quando CKPT_GENERATE_FALLBACK=true"
    unset CKPT_GENERATE_FALLBACK
}

test_ckpt_create_generates_sprint_md_when_enabled() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    export CKPT_GENERATE_FALLBACK="true"
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Fallback test 2")
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/sprint-context.md" "Deve gerar sprint-context.md"
    unset CKPT_GENERATE_FALLBACK
}

test_ckpt_create_generates_guide_when_enabled() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    export CKPT_GENERATE_FALLBACK="true"
    local ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Fallback test 3")
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/reconstruction-guide.md" "Deve gerar reconstruction-guide.md"
    unset CKPT_GENERATE_FALLBACK
}

test_ckpt_create_no_fallback_when_disabled() {
    local isolated_dir="$(mktemp -d)"
    ensure_dir "$isolated_dir/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$isolated_dir/.aidev/state"
    cat > "$isolated_dir/.aidev/state/unified.json" << 'EOF'
{"version": "3.9.0", "session": {"project_name": "test"}}
EOF
    cat > "$isolated_dir/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{"sprint_id": "test", "status": "in_progress", "current_task": "task-1", "overall_progress": {"total_tasks": 1, "completed": 0}}
EOF
    export CKPT_GENERATE_FALLBACK="false"
    local ckpt_id=$(ckpt_create "$isolated_dir" "manual" "No fallback")
    local has_fallback=0
    [ -f "$isolated_dir/.aidev/state/fallback/last-checkpoint.md" ] && has_fallback=1
    assert_equals "0" "$has_fallback" "Nao deve gerar fallback quando CKPT_GENERATE_FALLBACK=false"
    unset CKPT_GENERATE_FALLBACK
    rm -rf "$isolated_dir"
}

test_ckpt_create_no_fallback_by_default() {
    local isolated_dir="$(mktemp -d)"
    ensure_dir "$isolated_dir/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$isolated_dir/.aidev/state"
    cat > "$isolated_dir/.aidev/state/unified.json" << 'EOF'
{"version": "3.9.0", "session": {"project_name": "test"}}
EOF
    cat > "$isolated_dir/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{"sprint_id": "test", "status": "in_progress", "current_task": "task-1", "overall_progress": {"total_tasks": 1, "completed": 0}}
EOF
    unset CKPT_GENERATE_FALLBACK
    local ckpt_id=$(ckpt_create "$isolated_dir" "manual" "Default no fallback")
    local has_fallback=0
    [ -f "$isolated_dir/.aidev/state/fallback/last-checkpoint.md" ] && has_fallback=1
    assert_equals "0" "$has_fallback" "Nao deve gerar fallback por padrao"
    rm -rf "$isolated_dir"
}

# MAIN
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  CHECKPOINT MANAGER TEST SUITE                                 ║"
echo "║  AI Dev Superpowers v4.0.0 - Sprint 5                         ║"
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
    test_ckpt_generate_restore_prompt_includes_project \
    test_ckpt_create_with_cognitive_context \
    test_ckpt_create_cognitive_hypothesis \
    test_ckpt_create_cognitive_mental_model \
    test_ckpt_create_without_cognitive_context_backward_compat \
    test_ckpt_create_cognitive_empty_defaults \
    test_ckpt_create_cognitive_observations_field \
    test_ckpt_create_cognitive_confidence_field \
    test_ckpt_create_cognitive_decisions_pending \
    test_restore_prompt_includes_cognitive_section \
    test_restore_prompt_includes_chain_of_thought \
    test_restore_prompt_includes_hypothesis \
    test_restore_prompt_includes_mental_model \
    test_restore_prompt_skips_empty_cognitive \
    test_ckpt_create_generates_fallback_when_enabled \
    test_ckpt_create_generates_sprint_md_when_enabled \
    test_ckpt_create_generates_guide_when_enabled \
    test_ckpt_create_no_fallback_when_disabled \
    test_ckpt_create_no_fallback_by_default

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
