#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3.2 - Integration Tests: Skills
# ============================================================================
# Testes de integracao para skills do Sprint 3:
# - Meta-Planning Skill
# - Validation Module
# - Memory Module
# ============================================================================

# Encontra o diretorio raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Carrega modulos
source "$PROJECT_ROOT/lib/core.sh"
source "$PROJECT_ROOT/lib/file-ops.sh"
source "$PROJECT_ROOT/lib/detection.sh"
source "$PROJECT_ROOT/lib/validation.sh"
source "$PROJECT_ROOT/lib/memory.sh"

# ============================================================================
# CONFIGURACAO DE TESTE
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0
TEST_TEMP_DIR=""

# Cores para output (reutiliza de core.sh se disponivel)
# core.sh ja define GREEN, RED, etc. como readonly

# Setup do ambiente de teste
setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    export CLI_INSTALL_PATH="$TEST_TEMP_DIR"
    export MEMORY_LOCAL_DIR="$TEST_TEMP_DIR/.aidev/memories"

    # Cria estrutura basica
    mkdir -p "$TEST_TEMP_DIR/.aidev/state"
    mkdir -p "$TEST_TEMP_DIR/.aidev/memories"
    mkdir -p "$TEST_TEMP_DIR/docs/plans"

    # Inicializa git para testes
    git -C "$TEST_TEMP_DIR" init -q 2>/dev/null || true
    git -C "$TEST_TEMP_DIR" config user.email "test@test.com" 2>/dev/null || true
    git -C "$TEST_TEMP_DIR" config user.name "Test" 2>/dev/null || true

    # Cria arquivo e commit inicial
    echo "test" > "$TEST_TEMP_DIR/README.md"
    git -C "$TEST_TEMP_DIR" add . 2>/dev/null || true
    git -C "$TEST_TEMP_DIR" commit -m "Initial commit" -q 2>/dev/null || true
}

# Cleanup apos testes
cleanup_test_env() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Funcao de assertion
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"

    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        return 1
    fi
}

assert_true() {
    local result="$1"
    local message="${2:-Expected true}"

    if [ "$result" = "0" ] || [ "$result" = "true" ]; then
        return 0
    else
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"

    if [ -f "$file" ]; then
        return 0
    else
        echo "  File not found: $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist}"

    if [ -d "$dir" ]; then
        return 0
    else
        echo "  Directory not found: $dir"
        return 1
    fi
}

# Runner de teste
run_test() {
    local test_name="$1"
    local test_fn="$2"

    echo -n "  Testing: $test_name... "

    # Setup
    setup_test_env

    # Executa teste
    local result=0
    eval "$test_fn" || result=1

    # Cleanup
    cleanup_test_env

    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}PASSED${NC}"
        ((TESTS_PASSED++)) || true
    else
        echo -e "${RED}FAILED${NC}"
        ((TESTS_FAILED++)) || true
    fi
}

# ============================================================================
# TESTES: VALIDATION MODULE
# ============================================================================

echo ""
echo "=============================================="
echo "  VALIDATION MODULE TESTS"
echo "=============================================="
echo ""

test_validation_design_not_exists() {
    # Sem arquivo de design
    VALIDATION_MODE="warning"
    if validate_design_exists >/dev/null 2>&1; then
        echo "  Should fail when no design exists"
        return 1
    fi
    return 0
}
run_test "validate_design_exists (missing)" test_validation_design_not_exists

test_validation_design_exists() {
    # Cria arquivo de design
    echo "# Design Document" > "$TEST_TEMP_DIR/docs/design.md"

    VALIDATION_MODE="warning"
    validate_design_exists >/dev/null 2>&1
    local result=$?
    assert_equals "0" "$result" "Should pass when design exists"
}
run_test "validate_design_exists (present)" test_validation_design_exists

test_validation_plan_not_exists() {
    VALIDATION_MODE="warning"
    if validate_plan_exists >/dev/null 2>&1; then
        echo "  Should fail when no plan exists"
        return 1
    fi
    return 0
}
run_test "validate_plan_exists (missing)" test_validation_plan_not_exists

test_validation_plan_exists() {
    echo "# Implementation Plan" > "$TEST_TEMP_DIR/docs/plans/test-implementation.md"

    VALIDATION_MODE="warning"
    validate_plan_exists >/dev/null 2>&1
    local result=$?
    assert_equals "0" "$result" "Should pass when plan exists"
}
run_test "validate_plan_exists (present)" test_validation_plan_exists

test_validation_git_clean() {
    VALIDATION_MODE="warning"
    validate_git_clean >/dev/null 2>&1
    local result=$?
    assert_equals "0" "$result" "Should pass when git is clean"
}
run_test "validate_git_clean (clean)" test_validation_git_clean

test_validation_git_dirty() {
    # Cria arquivo nao commitado
    echo "new content" > "$TEST_TEMP_DIR/dirty.txt"

    VALIDATION_MODE="warning"
    if validate_git_clean >/dev/null 2>&1; then
        echo "  Should fail when git has uncommitted changes"
        return 1
    fi
    return 0
}
run_test "validate_git_clean (dirty)" test_validation_git_dirty

test_validation_prerequisites_brainstorming() {
    VALIDATION_MODE="warning"
    validate_prerequisites "brainstorming" >/dev/null 2>&1
    local result=$?
    assert_equals "0" "$result" "Brainstorming should have no prerequisites"
}
run_test "validate_prerequisites (brainstorming)" test_validation_prerequisites_brainstorming

test_validation_prerequisites_writing_plans() {
    # Sem design
    VALIDATION_MODE="warning"
    if validate_prerequisites "writing-plans" >/dev/null 2>&1; then
        echo "  writing-plans should require design"
        return 1
    fi
    return 0
}
run_test "validate_prerequisites (writing-plans, missing design)" test_validation_prerequisites_writing_plans

test_validation_prerequisites_writing_plans_ok() {
    # Com design
    echo "# Design" > "$TEST_TEMP_DIR/docs/design.md"

    VALIDATION_MODE="warning"
    validate_prerequisites "writing-plans" >/dev/null 2>&1
    local result=$?
    assert_equals "0" "$result" "writing-plans should pass with design"
}
run_test "validate_prerequisites (writing-plans, with design)" test_validation_prerequisites_writing_plans_ok

test_validation_safe_path() {
    # Path seguro
    _validate_safe_path "$TEST_TEMP_DIR/safe/path" >/dev/null 2>&1
    local result=$?
    assert_equals "0" "$result" "Safe path should pass"
}
run_test "_validate_safe_path (safe)" test_validation_safe_path

test_validation_dangerous_path() {
    # Path perigoso
    if _validate_safe_path "/" >/dev/null 2>&1; then
        echo "  Root path should be blocked"
        return 1
    fi
    return 0
}
run_test "_validate_safe_path (dangerous)" test_validation_dangerous_path

# ============================================================================
# TESTES: MEMORY MODULE
# ============================================================================

echo ""
echo "=============================================="
echo "  MEMORY MODULE TESTS"
echo "=============================================="
echo ""

test_memory_init() {
    memory_init >/dev/null 2>&1

    assert_dir_exists "$MEMORY_LOCAL_DIR" "Memory directory should be created"
    assert_file_exists "$MEMORY_LOCAL_DIR/index.json" "Index file should be created"
}
run_test "memory_init" test_memory_init

test_memory_save() {
    memory_init >/dev/null 2>&1
    memory_save "Test Lesson" "This is a test lesson content" "test,integration" >/dev/null 2>&1

    # Verifica se arquivo foi criado
    local count
    count=$(find "$MEMORY_LOCAL_DIR" -name "*.md" -type f | wc -l)
    assert_equals "1" "$count" "Should create one memory file"
}
run_test "memory_save" test_memory_save

test_memory_search_local() {
    memory_init >/dev/null 2>&1
    memory_save "Auth Error" "Error in authentication flow JWT token" "debug,auth" >/dev/null 2>&1
    memory_save "Database Fix" "Fixed connection pooling issue" "debug,database" >/dev/null 2>&1

    # Busca por termo existente
    local result
    result=$(_memory_search_local "auth" 5 2>&1)

    # Deve encontrar a memoria de auth
    if echo "$result" | grep -q "Auth Error"; then
        return 0
    else
        echo "  Search should find 'Auth Error' memory"
        return 1
    fi
}
run_test "memory_search_local" test_memory_search_local

test_memory_classify_task_debug() {
    local result
    result=$(_memory_classify_task "fix bug in authentication")
    assert_equals "debug" "$result" "Should classify as debug"
}
run_test "_memory_classify_task (debug)" test_memory_classify_task_debug

test_memory_classify_task_feature() {
    local result
    result=$(_memory_classify_task "implementar nova feature de login")
    assert_equals "feature" "$result" "Should classify as feature"
}
run_test "_memory_classify_task (feature)" test_memory_classify_task_feature

test_memory_classify_task_refactor() {
    local result
    result=$(_memory_classify_task "refactor the auth module")
    assert_equals "refactor" "$result" "Should classify as refactor"
}
run_test "_memory_classify_task (refactor)" test_memory_classify_task_refactor

test_memory_extract_keywords() {
    local result
    result=$(_memory_extract_keywords "implementar autenticacao com JWT token")

    # Deve extrair keywords relevantes
    if echo "$result" | grep -q "implementar" && \
       echo "$result" | grep -q "autenticacao" && \
       echo "$result" | grep -q "token"; then
        return 0
    else
        echo "  Should extract relevant keywords"
        echo "  Got: $result"
        return 1
    fi
}
run_test "_memory_extract_keywords" test_memory_extract_keywords

test_memory_suggest_output() {
    memory_init >/dev/null 2>&1

    local result
    result=$(memory_suggest "debug memory leak" 2>&1)

    # Deve ter output com sugestoes
    if echo "$result" | grep -q "Sugestoes"; then
        return 0
    else
        echo "  Should output suggestions"
        return 1
    fi
}
run_test "memory_suggest" test_memory_suggest_output

test_memory_list_recent() {
    memory_init >/dev/null 2>&1
    memory_save "Lesson 1" "Content 1" "tag1" >/dev/null 2>&1
    memory_save "Lesson 2" "Content 2" "tag2" >/dev/null 2>&1

    local result
    result=$(memory_list_recent 10 2>&1)

    # Deve listar memorias
    if echo "$result" | grep -q "Lesson"; then
        return 0
    else
        echo "  Should list recent memories"
        return 1
    fi
}
run_test "memory_list_recent" test_memory_list_recent

test_memory_stats() {
    memory_init >/dev/null 2>&1
    memory_save "Test" "Content" "" >/dev/null 2>&1

    local result
    result=$(memory_stats 2>&1)

    # Deve mostrar estatisticas
    if echo "$result" | grep -q "Total"; then
        return 0
    else
        echo "  Should show statistics"
        return 1
    fi
}
run_test "memory_stats" test_memory_stats

# ============================================================================
# TESTES: META-PLANNING SKILL (Template)
# ============================================================================

echo ""
echo "=============================================="
echo "  META-PLANNING SKILL TESTS"
echo "=============================================="
echo ""

test_meta_planning_template_exists() {
    local template="$PROJECT_ROOT/templates/skills/meta-planning/SKILL.md.tmpl"
    assert_file_exists "$template" "Meta-planning template should exist"
}
run_test "meta-planning template exists" test_meta_planning_template_exists

test_meta_planning_template_structure() {
    local template="$PROJECT_ROOT/templates/skills/meta-planning/SKILL.md.tmpl"

    if [ ! -f "$template" ]; then
        echo "  Template not found"
        return 1
    fi

    # Verifica estrutura basica
    local has_steps=false
    local has_checkpoints=false
    local has_transitions=false

    grep -q "## Step\|### Step" "$template" && has_steps=true
    grep -q "Checkpoint\|checkpoint" "$template" && has_checkpoints=true
    grep -qi "transic\|Proxima Skill" "$template" && has_transitions=true

    if [ "$has_steps" = true ] && [ "$has_checkpoints" = true ] && [ "$has_transitions" = true ]; then
        return 0
    else
        echo "  Template missing required sections"
        echo "  has_steps: $has_steps"
        echo "  has_checkpoints: $has_checkpoints"
        echo "  has_transitions: $has_transitions"
        return 1
    fi
}
run_test "meta-planning template structure" test_meta_planning_template_structure

# ============================================================================
# TESTES DE INTEGRACAO: VALIDATION + MEMORY
# ============================================================================

echo ""
echo "=============================================="
echo "  INTEGRATION TESTS"
echo "=============================================="
echo ""

test_integration_validation_log() {
    VALIDATION_MODE="warning"

    # Executa algumas validacoes
    validate_design_exists >/dev/null 2>&1
    validate_git_clean >/dev/null 2>&1

    # Verifica se log foi criado
    local log_file="$TEST_TEMP_DIR/.aidev/state/validations.json"

    if [ -f "$log_file" ]; then
        # Verifica se tem entradas
        if command -v jq >/dev/null 2>&1; then
            local count
            count=$(jq '.validations | length' "$log_file" 2>/dev/null || echo "0")
            if [ "$count" -gt 0 ]; then
                return 0
            fi
        fi
    fi

    echo "  Validation log should have entries"
    return 1
}
run_test "validation logging" test_integration_validation_log

test_integration_memory_workflow() {
    memory_init >/dev/null 2>&1

    # Simula workflow: debug start -> resolution -> save
    memory_save "Bug: Login Failure" "JWT token was expired" "bug,auth" >/dev/null 2>&1

    # Busca no proximo debug
    local result
    result=$(_memory_search_local "login" 3 2>&1)

    if echo "$result" | grep -q "Login Failure"; then
        return 0
    else
        echo "  Workflow should find previous bug"
        return 1
    fi
}
run_test "memory workflow (save -> search)" test_integration_memory_workflow

test_integration_validation_before_deploy() {
    # Simula validacao antes de deploy
    VALIDATION_MODE="strict"

    # Cria arquivo sujo
    echo "dirty" > "$TEST_TEMP_DIR/dirty.txt"

    # Deve falhar porque git nao esta limpo
    if validate_before_action "deploy" "" >/dev/null 2>&1; then
        echo "  Deploy should fail with dirty git"
        return 1
    fi
    return 0
}
run_test "validation before deploy (dirty git)" test_integration_validation_before_deploy

# ============================================================================
# SUMARIO
# ============================================================================

echo ""
echo "=============================================="
echo "  TEST SUMMARY"
echo "=============================================="
echo ""
echo -e "  ${GREEN}PASSED${NC}: $TESTS_PASSED"
echo -e "  ${RED}FAILED${NC}: $TESTS_FAILED"
echo ""

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "  ${GREEN}All $TOTAL tests passed!${NC}"
    exit 0
else
    echo -e "  ${RED}$TESTS_FAILED of $TOTAL tests failed${NC}"
    exit 1
fi
