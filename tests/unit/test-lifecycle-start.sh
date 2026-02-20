#!/bin/bash

# ============================================================================
# Testes Unitários - cmd_start (flc_feature_start)
# Feature Lifecycle Automation - Sprint 2
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
TEST_TMP="/tmp/aidev-lifecycle-start-test-$$"

FIXTURE_FEATURE='# Feature: Autenticacao OAuth

**Status:** Planejada
**Prioridade:** Alta
**Criado:** 2026-02-20

## Sprints

| Sprint | Objetivo | Status |
|---|---|---|
| Sprint 1 | Implementar login | Pendente |
| Sprint 2 | Testes e2e | Pendente |
'

setup() {
    mkdir -p "$TEST_TMP/.aidev/plans/backlog"
    mkdir -p "$TEST_TMP/.aidev/plans/features"
    mkdir -p "$TEST_TMP/.aidev/plans/current"
    mkdir -p "$TEST_TMP/.aidev/plans/history"
    mkdir -p "$TEST_TMP/.aidev/state"
    mkdir -p "$TEST_TMP/.aidev/lib"
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    touch "$TEST_TMP/.aidev/.initialized"
    # Cria feature de teste em features/
    echo "$FIXTURE_FEATURE" > "$TEST_TMP/.aidev/plans/features/autenticacao-oauth.md"
    # README de features
    cat > "$TEST_TMP/.aidev/plans/features/README.md" <<'EOF'
# Features

## Em Execucao

| Feature | Arquivo | Movida em |
|---|---|---|

## Concluidas

| Feature | History | Data |
|---|---|---|
EOF
    # README de current
    cat > "$TEST_TMP/.aidev/plans/current/README.md" <<'EOF'
# Current

*Nenhuma feature em execucao no momento.*
EOF
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ============================================================================
# Sprint 2: move arquivo de features/ para current/
# ============================================================================

test_section "cmd_start: move arquivo de features/ para current/"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" start autenticacao-oauth 2>/dev/null
)
[ -f "$TEST_TMP/.aidev/plans/current/autenticacao-oauth.md" ]
assert_equals "0" "$?" "Arquivo movido para current/"
[ ! -f "$TEST_TMP/.aidev/plans/features/autenticacao-oauth.md" ]
assert_equals "0" "$?" "Arquivo removido de features/"
teardown

# ============================================================================
# Sprint 2: bloqueia se já houver feature ativa em current/
# ============================================================================

test_section "cmd_start: bloqueia se ja houver feature em current/"

setup
# Simula feature já ativa
echo "# Feature Ativa" > "$TEST_TMP/.aidev/plans/current/outra-feature.md"
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" start autenticacao-oauth 2>&1
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "Bloqueia com exit 1 quando ha feature ativa"
echo "$result" | grep -qi "ativa\|active\|current\|complete"
assert_equals "0" "$?" "Exibe mensagem explicando o bloqueio"
teardown

# ============================================================================
# Sprint 2: current/README.md é atualizado
# ============================================================================

test_section "cmd_start: atualiza current/README.md"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" start autenticacao-oauth 2>/dev/null
)
grep -qi "Autenticacao OAuth\|autenticacao-oauth" "$TEST_TMP/.aidev/plans/current/README.md"
assert_equals "0" "$?" "current/README.md menciona a feature iniciada"
teardown

# ============================================================================
# Sprint 2: feature não encontrada em features/ retorna erro
# ============================================================================

test_section "cmd_start: feature inexistente retorna erro"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" start feature-que-nao-existe 2>&1
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "Feature inexistente retorna exit 1"
teardown

# ============================================================================
# Sprint 2: sem argumento retorna erro
# ============================================================================

test_section "cmd_start: sem argumento retorna erro"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" start 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "cmd_start sem argumento retorna exit 1"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
