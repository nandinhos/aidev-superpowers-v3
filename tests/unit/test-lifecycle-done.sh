#!/bin/bash

# ============================================================================
# Testes Unitários - cmd_done (flc_sprint_done)
# Feature Lifecycle Automation - Sprint 3
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
TEST_TMP="/tmp/aidev-lifecycle-done-test-$$"

FIXTURE_CURRENT_README='# Current - Em Execucao

## Feature Ativa

### Autenticacao OAuth

| Sprint | Objetivo | Status |
|---|---|---|
| Sprint 1 | Implementar login | Pendente |
| Sprint 2 | Testes e2e | Pendente |

*Ultima atualizacao: 2026-02-20*
'

setup() {
    mkdir -p "$TEST_TMP/.aidev/plans/current"
    mkdir -p "$TEST_TMP/.aidev/state/sprints/current/checkpoints"
    mkdir -p "$TEST_TMP/.aidev/memory/kb"
    mkdir -p "$TEST_TMP/.aidev/lib"
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    touch "$TEST_TMP/.aidev/.initialized"
    echo "$FIXTURE_CURRENT_README" > "$TEST_TMP/.aidev/plans/current/README.md"
    echo "# Feature Ativa" > "$TEST_TMP/.aidev/plans/current/autenticacao-oauth.md"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ============================================================================
# Sprint 3: atualiza status na tabela do current/README
# ============================================================================

test_section "cmd_done: atualiza status na tabela do current/README"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" done "Sprint 1" "Login implementado" 2>/dev/null
)
grep -qi "Concluida\|Concluído\|concluida" "$TEST_TMP/.aidev/plans/current/README.md"
assert_equals "0" "$?" "Status da sprint atualizado para Concluida no README"
# Sprint 1 não deve mais ter "Pendente"
grep "Sprint 1" "$TEST_TMP/.aidev/plans/current/README.md" | grep -qi "Pendente"
assert_equals "1" "$?" "Sprint 1 nao tem mais status Pendente"
teardown

# ============================================================================
# Sprint 3: sprint nao existente ainda retorna sucesso (linha nao existe mas nao falha)
# ============================================================================

test_section "cmd_done: sprint inexistente nao quebra"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" done "Sprint 99" 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:0"
assert_equals "0" "$?" "Sprint inexistente retorna exit 0 (nao bloqueia)"
teardown

# ============================================================================
# Sprint 3: quando todas as sprints concluidas, sugere cmd_complete
# ============================================================================

test_section "cmd_done: sugere complete quando tudo concluido"

setup
# Conclui Sprint 1
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" done "Sprint 1" 2>/dev/null
)
# Conclui Sprint 2 — agora todas estão concluídas
output=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" done "Sprint 2" 2>/dev/null
)
echo "$output" | grep -qi "complete\|concluidas\|finalizar"
assert_equals "0" "$?" "Sugere aidev complete quando todas as sprints estao concluidas"
teardown

# ============================================================================
# Sprint 3: sem argumento retorna erro
# ============================================================================

test_section "cmd_done: sem argumento retorna erro"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" done 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "cmd_done sem argumento retorna exit 1"
teardown

# ============================================================================
# Sprint 3: sem current/README (sem feature ativa) retorna erro
# ============================================================================

test_section "cmd_done: sem feature ativa retorna erro"

setup
rm "$TEST_TMP/.aidev/plans/current/README.md"
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" done "Sprint 1" 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "Sem feature ativa retorna exit 1"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
