#!/bin/bash

# ============================================================================
# Testes Unitários - cmd_complete (flc_feature_complete)
# Feature Lifecycle Automation - Sprint 4
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
TEST_TMP="/tmp/aidev-lifecycle-complete-test-$$"

setup() {
    mkdir -p "$TEST_TMP/.aidev/plans/backlog"
    mkdir -p "$TEST_TMP/.aidev/plans/features"
    mkdir -p "$TEST_TMP/.aidev/plans/current"
    mkdir -p "$TEST_TMP/.aidev/plans/history"
    mkdir -p "$TEST_TMP/.aidev/state/sprints/current/checkpoints"
    mkdir -p "$TEST_TMP/.aidev/memory/kb"
    mkdir -p "$TEST_TMP/.aidev/lib"
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    touch "$TEST_TMP/.aidev/.initialized"
    echo "4.5.5" > "$TEST_TMP/VERSION"

    # Feature ativa em current/
    cat > "$TEST_TMP/.aidev/plans/current/autenticacao-oauth.md" <<'EOF'
# Autenticacao OAuth

**Status:** Em execucao
**Prioridade:** Alta

| Sprint | Status |
|---|---|
| Sprint 1 | Concluida |
| Sprint 2 | Concluida |
EOF

    # READMEs básicos
    cat > "$TEST_TMP/.aidev/plans/current/README.md" <<'EOF'
# Current

## Feature Ativa

### Autenticacao OAuth
EOF

    cat > "$TEST_TMP/.aidev/plans/features/README.md" <<'EOF'
# Features

## Em Execucao

| Feature | Arquivo | Movida em |
|---|---|---|
| Autenticacao OAuth | [current/](../current/autenticacao-oauth.md) | 2026-02-20 |

## Concluidas

| Feature | History | Data |
|---|---|---|
EOF

    cat > "$TEST_TMP/.aidev/plans/backlog/README.md" <<'EOF'
# Backlog

## Ideias Pendentes

## Concluidas

| Item | Destino | Data |
|---|---|---|
EOF

    cat > "$TEST_TMP/.aidev/plans/ROADMAP.md" <<'EOF'
# ROADMAP

Conteudo antigo com 300 linhas que deve ser substituido por indice.
EOF
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ============================================================================
# Sprint 4: move arquivo de current/ para history/YYYY-MM/
# ============================================================================

test_section "cmd_complete: move arquivo de current/ para history/YYYY-MM/"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete autenticacao-oauth 2>/dev/null
)
# Arquivo deve existir em algum subdiretório de history/
moved=$(find "$TEST_TMP/.aidev/plans/history" -name "*autenticacao*oauth*" 2>/dev/null | head -1)
[ -n "$moved" ]
assert_equals "0" "$?" "Arquivo movido para history/YYYY-MM/"
# Não deve mais estar em current/
[ ! -f "$TEST_TMP/.aidev/plans/current/autenticacao-oauth.md" ]
assert_equals "0" "$?" "Arquivo removido de current/"
teardown

# ============================================================================
# Sprint 4: current/README.md é resetado (sem feature ativa)
# ============================================================================

test_section "cmd_complete: current/README.md resetado"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete autenticacao-oauth 2>/dev/null
)
grep -qi "Nenhuma\|nenhuma\|sem feature\|None" "$TEST_TMP/.aidev/plans/current/README.md"
assert_equals "0" "$?" "current/README.md indica que nao ha feature ativa"
grep -qi "Autenticacao OAuth\|autenticacao-oauth" "$TEST_TMP/.aidev/plans/current/README.md"
assert_equals "1" "$?" "current/README.md nao menciona mais a feature concluida"
teardown

# ============================================================================
# Sprint 4: ROADMAP.md é reconstruído como índice
# ============================================================================

test_section "cmd_complete: ROADMAP.md reconstruido como indice"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete autenticacao-oauth 2>/dev/null
)
# ROADMAP deve ter o novo formato
grep -qi "backlog\|features\|current\|history" "$TEST_TMP/.aidev/plans/ROADMAP.md"
assert_equals "0" "$?" "ROADMAP menciona estrutura de planejamento"
# Deve ser pequeno (indice, nao conteudo detalhado)
local_lines=$(wc -l < "$TEST_TMP/.aidev/plans/ROADMAP.md")
[ "$local_lines" -le 80 ]
assert_equals "0" "$?" "ROADMAP tem no maximo 80 linhas (atual: $local_lines)"
teardown

# ============================================================================
# Sprint 4: feature não encontrada em current/ retorna erro
# ============================================================================

test_section "cmd_complete: feature inexistente retorna erro"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete feature-inexistente 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "Feature inexistente retorna exit 1"
teardown

# ============================================================================
# Sprint 4: sem argumento retorna erro
# ============================================================================

test_section "cmd_complete: sem argumento retorna erro"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:1"
assert_equals "0" "$?" "cmd_complete sem argumento retorna exit 1"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
