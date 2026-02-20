#!/bin/bash

# ============================================================================
# Testes Unitários - cmd_plan (flc_plan_create)
# Feature Lifecycle Automation - Sprint 1
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
FLC_MODULE="$ROOT_DIR/lib/feature-lifecycle-cli.sh"
TEST_TMP="/tmp/aidev-lifecycle-plan-test-$$"

# ============================================================================
# Setup / Teardown
# ============================================================================

setup() {
    mkdir -p "$TEST_TMP/.aidev/plans/backlog"
    mkdir -p "$TEST_TMP/.aidev/plans/features"
    mkdir -p "$TEST_TMP/.aidev/plans/current"
    mkdir -p "$TEST_TMP/.aidev/plans/history"
    mkdir -p "$TEST_TMP/.aidev/state"
    mkdir -p "$TEST_TMP/.aidev/lib"
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    # Marca como aidev instalado
    touch "$TEST_TMP/.aidev/.initialized"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ============================================================================
# Sprint 1: flc_plan_create — cria arquivo em backlog/
# ============================================================================

test_section "cmd_plan: cria arquivo em backlog/"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" plan "Minha Feature Teste" 2>/dev/null
    echo "exit:$?"
)
# Verifica que foi criado algum arquivo em backlog/
created=$(find "$TEST_TMP/.aidev/plans/backlog" -name "*.md" 2>/dev/null | head -1)
[ -n "$created" ]
assert_equals "0" "$?" "aidev plan cria arquivo .md em backlog/"
teardown

# ============================================================================
# Sprint 1: título com espaços → kebab-case no nome do arquivo
# ============================================================================

test_section "cmd_plan: titulo com espacos vira kebab-case"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" plan "Autenticacao OAuth Google" 2>/dev/null
)
created=$(find "$TEST_TMP/.aidev/plans/backlog" -name "*autenticacao*oauth*google*" 2>/dev/null | head -1)
[ -n "$created" ]
assert_equals "0" "$?" "Nome com espacos gera arquivo kebab-case"
teardown

# ============================================================================
# Sprint 1: arquivo tem campos obrigatorios (titulo, status, prioridade, criado)
# ============================================================================

test_section "cmd_plan: arquivo tem campos obrigatorios"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" plan "Feature Com Campos" 2>/dev/null
)
file=$(find "$TEST_TMP/.aidev/plans/backlog" -name "*.md" 2>/dev/null | head -1)
if [ -n "$file" ]; then
    grep -qi "status\|Status" "$file"
    assert_equals "0" "$?" "Arquivo tem campo Status"

    grep -qi "prioridade\|priority\|Prioridade" "$file"
    assert_equals "0" "$?" "Arquivo tem campo Prioridade"

    grep -qi "$(date +%Y)" "$file"
    assert_equals "0" "$?" "Arquivo tem data de criacao com ano atual"
else
    assert_equals "0" "1" "Arquivo nao foi criado — nao e possivel verificar campos"
fi
teardown

# ============================================================================
# Sprint 1: arquivo ja existente — retorna aviso sem sobrescrever
# ============================================================================

test_section "cmd_plan: arquivo existente nao e sobrescrito"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" plan "Feature Existente" 2>/dev/null
)
file=$(find "$TEST_TMP/.aidev/plans/backlog" -name "*feature*existente*" 2>/dev/null | head -1)
if [ -n "$file" ]; then
    echo "CONTEUDO ORIGINAL" >> "$file"
    (
        cd "$TEST_TMP"
        AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" plan "Feature Existente" 2>/dev/null
    )
    grep -q "CONTEUDO ORIGINAL" "$file"
    assert_equals "0" "$?" "Arquivo existente nao foi sobrescrito"
else
    assert_equals "0" "1" "Arquivo nao foi criado na primeira chamada"
fi
teardown

# ============================================================================
# Sprint 1: sem titulo — retorna erro com uso
# ============================================================================

test_section "cmd_plan: sem titulo retorna erro"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" plan 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "aidev plan sem argumento retorna exit 1"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
