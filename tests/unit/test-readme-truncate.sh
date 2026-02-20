#!/bin/bash

# ============================================================================
# Testes Unitários - otimizar READMEs de backlog/ e features/
# Sprint 1: truncar seções "Concluídas" a 5 entradas
# Sprint 2: índice consolidado em history/README.md
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
TEST_TMP="/tmp/aidev-readme-truncate-test-$$"

# Helper: monta ambiente minimo com N features já concluidas na tabela
setup_with_n_completed() {
    local n="$1"
    mkdir -p "$TEST_TMP/.aidev/plans/backlog"
    mkdir -p "$TEST_TMP/.aidev/plans/features"
    mkdir -p "$TEST_TMP/.aidev/plans/current"
    mkdir -p "$TEST_TMP/.aidev/plans/history/2026-02"
    mkdir -p "$TEST_TMP/.aidev/state"
    mkdir -p "$TEST_TMP/.aidev/lib"
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    touch "$TEST_TMP/.aidev/.initialized"

    # Monta features/README.md com N entradas já concluidas
    {
        echo "# Features"
        echo ""
        echo "## Em Execucao"
        echo ""
        echo "| Feature | Arquivo | Movida em |"
        echo "|---|---|---|"
        echo ""
        echo "---"
        echo ""
        echo "## Concluidas"
        echo ""
        echo "| Feature | History | Data |"
        echo "|---|---|---|"
        for i in $(seq 1 "$n"); do
            echo "| Feature Antiga $i | [history/2026-01/](../history/2026-01/) | 2026-01-0$i |"
        done
        echo ""
        echo "---"
        echo ""
        echo "*Ultima atualizacao: 2026-02-01*"
    } > "$TEST_TMP/.aidev/plans/features/README.md"

    # Monta backlog/README.md com N entradas já concluidas
    {
        echo "# Backlog"
        echo ""
        echo "## Ideias"
        echo ""
        echo "| Ideia | Prioridade | Criado |"
        echo "|---|---|---|"
        echo ""
        echo "---"
        echo ""
        echo "## Concluidas"
        echo ""
        echo "| Ideia | Status | Data |"
        echo "|---|---|---|"
        for i in $(seq 1 "$n"); do
            echo "| Ideia Antiga $i | Concluido em history/ | 2026-01-0$i |"
        done
        echo ""
        echo "---"
        echo ""
        echo "*Ultima atualizacao: 2026-02-01*"
    } > "$TEST_TMP/.aidev/plans/backlog/README.md"

    # Cria feature nova em current/ para completar
    cat > "$TEST_TMP/.aidev/plans/current/nova-feature.md" <<'EOF'
# Feature: Nova Feature de Teste

**Status:** Em andamento

## Sprints

| Sprint | Objetivo | Status |
|---|---|---|
| Sprint 1 | Implementar | Concluida |
EOF

    cat > "$TEST_TMP/.aidev/plans/current/README.md" <<'EOF'
# Current

*Nova Feature de Teste em execucao.*
EOF
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ============================================================================
# Sprint 1: após complete com 5 já existentes, seção fica com 6 (5+1 novo)
# ============================================================================

test_section "truncagem: com 5 pre-existentes, apos complete tem max 5"

setup_with_n_completed 5
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete nova-feature 2>/dev/null
)
# Conta linhas de dados na seção Concluídas de features/README.md (usando awk para delimitar seção)
count=$(awk '/## Concluidas/{in_s=1;next} in_s && /^---/{in_s=0} in_s && /^\| / && !/^\|---/{count++} END{print count+0}' \
    "$TEST_TMP/.aidev/plans/features/README.md" 2>/dev/null)
# Subtrai 1 para descontar cabeçalho da tabela
data_count=$(( ${count:-0} - 1 ))
[ "$data_count" -le 5 ]
assert_equals "0" "$?" "features/README.md: secao Concluidas tem no maximo 5 entradas (tem $data_count)"
teardown

# ============================================================================
# Sprint 1: após complete com 3 já existentes, seção cresce para 4 (< 5)
# ============================================================================

test_section "truncagem: com 3 pre-existentes, apos complete tem 4"

setup_with_n_completed 3
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete nova-feature 2>/dev/null
)
count=$(awk '/## Concluidas/{in_s=1;next} in_s && /^---/{in_s=0} in_s && /^\| / && !/^\|---/{count++} END{print count+0}' \
    "$TEST_TMP/.aidev/plans/features/README.md" 2>/dev/null)
data_count=$(( ${count:-0} - 1 ))
[ "$data_count" -ge 4 ]
assert_equals "0" "$?" "features/README.md: com 3+1, deve ter pelo menos 4 (tem $data_count)"
teardown

# ============================================================================
# Sprint 1: backlog/README.md também limitado a 5 entradas
# ============================================================================

test_section "truncagem: backlog/README.md limitado a 5 entradas"

setup_with_n_completed 7
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete nova-feature 2>/dev/null
)
count=$(awk '/## Concluidas/{in_s=1;next} in_s && /^---/{in_s=0} in_s && /^\| / && !/^\|---/{count++} END{print count+0}' \
    "$TEST_TMP/.aidev/plans/backlog/README.md" 2>/dev/null)
data_count=$(( ${count:-0} - 1 ))
[ "$data_count" -le 5 ]
assert_equals "0" "$?" "backlog/README.md: secao Concluidas tem no maximo 5 entradas (tem $data_count)"
teardown

# ============================================================================
# Sprint 2: history/README.md é criado/atualizado com índice completo
# ============================================================================

test_section "history/README.md: criado como indice consolidado apos complete"

setup_with_n_completed 2
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete nova-feature 2>/dev/null
)
[ -f "$TEST_TMP/.aidev/plans/history/README.md" ]
assert_equals "0" "$?" "history/README.md foi criado apos complete"
teardown

# ============================================================================
# Sprint 2: history/README.md contém link para o mês da feature concluída
# ============================================================================

test_section "history/README.md: contem link para o mes atual"

setup_with_n_completed 1
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" complete nova-feature 2>/dev/null
)
month=$(date +%Y-%m)
grep -q "$month" "$TEST_TMP/.aidev/plans/history/README.md" 2>/dev/null
assert_equals "0" "$?" "history/README.md menciona o mes atual ($month)"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
