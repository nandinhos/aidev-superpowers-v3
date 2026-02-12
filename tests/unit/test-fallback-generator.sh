#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Fallback Generator Tests
# ============================================================================
# Testes unitarios para o modulo fallback-generator.sh
# Sprint 5 - Feature 5.3.1
# TDD: RED phase
#
# Uso: ./test-fallback-generator.sh
# ============================================================================

TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
source "$ROOT_DIR/lib/checkpoint-manager.sh"
source "$ROOT_DIR/lib/fallback-generator.sh"

# ============================================================================
# HELPERS
# ============================================================================

setup_test_env() {
    ensure_dir "$TEST_DIR/.aidev/state/sprints/current/checkpoints"
    ensure_dir "$TEST_DIR/.aidev/state/fallback"
    ensure_dir "$TEST_DIR/.aidev/state"
}

create_mock_unified() {
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "4.0.0",
  "session": {
    "id": "test-session-001",
    "project_name": "meu-projeto",
    "stack": "bash"
  },
  "active_intent": "feature_request",
  "intent_description": "Implementando fallback generator"
}
EOF
}

create_mock_sprint_status() {
    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'EOF'
{
  "sprint_id": "sprint-5-estado-ubiquo",
  "sprint_name": "Sprint 5: Orquestracao por Estado Ubiquo",
  "status": "in_progress",
  "current_task": "task-5.3.1-fallback-generator",
  "overall_progress": {
    "total_tasks": 14,
    "completed": 4,
    "in_progress": 1,
    "pending": 9,
    "blocked": 0
  },
  "tasks": [
    {
      "task_id": "task-5.1.1-checkpoint-cognitive-context",
      "name": "Extender schema do checkpoint",
      "status": "completed",
      "feature": "5.1",
      "file": "lib/checkpoint-manager.sh"
    },
    {
      "task_id": "task-5.3.1-fallback-generator",
      "name": "Criar modulo fallback-generator.sh",
      "status": "in_progress",
      "feature": "5.3",
      "file": "lib/fallback-generator.sh"
    },
    {
      "task_id": "task-5.2.1-context-git",
      "name": "Criar modulo context-git.sh",
      "status": "pending",
      "feature": "5.2",
      "file": "lib/context-git.sh"
    }
  ]
}
EOF
}

create_mock_checkpoint() {
    setup_test_env
    create_mock_unified
    create_mock_sprint_status
    local ckpt_id
    ckpt_id=$(ckpt_create "$TEST_DIR" "manual" "Checkpoint de teste" \
        "Implementando o gerador de fallback" \
        "Preciso gerar Markdown puro" \
        "Checkpoint -> Fallback MD -> LLM sem MCP le")
    echo "$ckpt_id"
}

# ============================================================================
# TESTES: fallback_checkpoint_to_md
# ============================================================================

test_fallback_checkpoint_to_md_basic() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_checkpoint_to_md "$ckpt_file")
    assert_not_equals "" "$result" "Deve gerar conteudo Markdown"
}

test_fallback_checkpoint_to_md_has_title() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_checkpoint_to_md "$ckpt_file")
    assert_contains "$result" "# Checkpoint" "Deve ter titulo com # Checkpoint"
}

test_fallback_checkpoint_to_md_has_cognitive() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_checkpoint_to_md "$ckpt_file")
    assert_contains "$result" "Implementando o gerador de fallback" "Deve incluir chain_of_thought"
}

test_fallback_checkpoint_to_md_has_sprint_info() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_checkpoint_to_md "$ckpt_file")
    assert_contains "$result" "Sprint" "Deve incluir info da sprint"
}

test_fallback_checkpoint_to_md_invalid_file() {
    fallback_checkpoint_to_md "/nonexistent.json" > /dev/null 2>&1
    local exit_code=$?
    assert_not_equals "0" "$exit_code" "Deve retornar erro para arquivo inexistente"
}

# ============================================================================
# TESTES: fallback_sprint_to_md
# ============================================================================

test_fallback_sprint_to_md_basic() {
    setup_test_env
    create_mock_sprint_status
    local result=$(fallback_sprint_to_md "$TEST_DIR")
    assert_not_equals "" "$result" "Deve gerar conteudo Markdown"
}

test_fallback_sprint_to_md_has_title() {
    setup_test_env
    create_mock_sprint_status
    local result=$(fallback_sprint_to_md "$TEST_DIR")
    assert_contains "$result" "# Sprint" "Deve ter titulo com # Sprint"
}

test_fallback_sprint_to_md_has_progress() {
    setup_test_env
    create_mock_sprint_status
    local result=$(fallback_sprint_to_md "$TEST_DIR")
    assert_contains "$result" "Progresso" "Deve ter secao de progresso"
}

test_fallback_sprint_to_md_has_tasks() {
    setup_test_env
    create_mock_sprint_status
    local result=$(fallback_sprint_to_md "$TEST_DIR")
    assert_contains "$result" "task-5.3.1" "Deve listar tasks"
}

test_fallback_sprint_to_md_shows_task_status() {
    setup_test_env
    create_mock_sprint_status
    local result=$(fallback_sprint_to_md "$TEST_DIR")
    assert_contains "$result" "completed" "Deve mostrar status das tasks"
}

test_fallback_sprint_to_md_no_file() {
    local isolated_dir="$(mktemp -d)"
    fallback_sprint_to_md "$isolated_dir" > /dev/null 2>&1
    local exit_code=$?
    assert_not_equals "0" "$exit_code" "Deve retornar erro sem sprint-status.json"
    rm -rf "$isolated_dir"
}

# ============================================================================
# TESTES: fallback_files_to_md
# ============================================================================

test_fallback_files_to_md_basic() {
    setup_test_env
    create_mock_sprint_status
    # Cria arquivos fake que estao "em trabalho"
    ensure_dir "$TEST_DIR/lib"
    echo '#!/bin/bash\necho "hello"' > "$TEST_DIR/lib/fallback-generator.sh"
    local result=$(fallback_files_to_md "$TEST_DIR")
    assert_not_equals "" "$result" "Deve gerar conteudo Markdown"
}

test_fallback_files_to_md_has_title() {
    setup_test_env
    create_mock_sprint_status
    ensure_dir "$TEST_DIR/lib"
    echo '#!/bin/bash' > "$TEST_DIR/lib/fallback-generator.sh"
    local result=$(fallback_files_to_md "$TEST_DIR")
    assert_contains "$result" "# Arquivos" "Deve ter titulo com # Arquivos"
}

test_fallback_files_to_md_lists_task_files() {
    setup_test_env
    create_mock_sprint_status
    # O mock tem task in_progress com file "lib/fallback-generator.sh"
    ensure_dir "$TEST_DIR/lib"
    echo '#!/bin/bash' > "$TEST_DIR/lib/fallback-generator.sh"
    local result=$(fallback_files_to_md "$TEST_DIR")
    assert_contains "$result" "lib/fallback-generator.sh" "Deve listar arquivo da task ativa"
}

# ============================================================================
# TESTES: fallback_guide_to_md
# ============================================================================

test_fallback_guide_to_md_basic() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_guide_to_md "$TEST_DIR" "$ckpt_file")
    assert_not_equals "" "$result" "Deve gerar conteudo Markdown"
}

test_fallback_guide_to_md_has_title() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_guide_to_md "$TEST_DIR" "$ckpt_file")
    assert_contains "$result" "# Guia de Retomada" "Deve ter titulo de guia"
}

test_fallback_guide_to_md_has_instructions() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_guide_to_md "$TEST_DIR" "$ckpt_file")
    assert_contains "$result" "Instruc" "Deve ter secao de instrucoes"
}

test_fallback_guide_to_md_references_sprint() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_guide_to_md "$TEST_DIR" "$ckpt_file")
    assert_contains "$result" "sprint" "Deve referenciar a sprint"
}

# ============================================================================
# TESTES: fallback_generate_all
# ============================================================================

test_fallback_generate_all_creates_dir() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    fallback_generate_all "$TEST_DIR" "$ckpt_file" > /dev/null 2>&1
    local fallback_dir="$TEST_DIR/.aidev/state/fallback"
    assert_true "$([ -d "$fallback_dir" ] && echo 0 || echo 1)" "Deve criar diretorio fallback"
}

test_fallback_generate_all_creates_checkpoint_md() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    fallback_generate_all "$TEST_DIR" "$ckpt_file" > /dev/null 2>&1
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/last-checkpoint.md" "Deve criar last-checkpoint.md"
}

test_fallback_generate_all_creates_sprint_md() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    fallback_generate_all "$TEST_DIR" "$ckpt_file" > /dev/null 2>&1
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/sprint-context.md" "Deve criar sprint-context.md"
}

test_fallback_generate_all_creates_files_md() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    fallback_generate_all "$TEST_DIR" "$ckpt_file" > /dev/null 2>&1
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/active-files.md" "Deve criar active-files.md"
}

test_fallback_generate_all_creates_guide_md() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    fallback_generate_all "$TEST_DIR" "$ckpt_file" > /dev/null 2>&1
    assert_file_exists "$TEST_DIR/.aidev/state/fallback/reconstruction-guide.md" "Deve criar reconstruction-guide.md"
}

test_fallback_generate_all_output_message() {
    local ckpt_id=$(create_mock_checkpoint)
    local ckpt_file="$TEST_DIR/.aidev/state/sprints/current/checkpoints/${ckpt_id}.json"
    local result=$(fallback_generate_all "$TEST_DIR" "$ckpt_file" 2>&1)
    assert_contains "$result" "fallback" "Deve confirmar geracao dos artefatos"
}

# MAIN
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  FALLBACK GENERATOR TEST SUITE - Sprint 5                      ║"
echo "║  AI Dev Superpowers v4.0.0 - Feature 5.3.1                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

run_test_suite "Fallback Generator Tests" \
    test_fallback_checkpoint_to_md_basic \
    test_fallback_checkpoint_to_md_has_title \
    test_fallback_checkpoint_to_md_has_cognitive \
    test_fallback_checkpoint_to_md_has_sprint_info \
    test_fallback_checkpoint_to_md_invalid_file \
    test_fallback_sprint_to_md_basic \
    test_fallback_sprint_to_md_has_title \
    test_fallback_sprint_to_md_has_progress \
    test_fallback_sprint_to_md_has_tasks \
    test_fallback_sprint_to_md_shows_task_status \
    test_fallback_sprint_to_md_no_file \
    test_fallback_files_to_md_basic \
    test_fallback_files_to_md_has_title \
    test_fallback_files_to_md_lists_task_files \
    test_fallback_guide_to_md_basic \
    test_fallback_guide_to_md_has_title \
    test_fallback_guide_to_md_has_instructions \
    test_fallback_guide_to_md_references_sprint \
    test_fallback_generate_all_creates_dir \
    test_fallback_generate_all_creates_checkpoint_md \
    test_fallback_generate_all_creates_sprint_md \
    test_fallback_generate_all_creates_files_md \
    test_fallback_generate_all_creates_guide_md \
    test_fallback_generate_all_output_message

rm -rf "$TEST_DIR"
exit $TESTS_FAILED
