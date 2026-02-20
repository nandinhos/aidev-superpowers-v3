#!/bin/bash

# ============================================================================
# Testes Unitários - _flc_roadmap_rebuild
# Feature Lifecycle Automation - Sprint 5
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
FLC_MODULE="$ROOT_DIR/lib/feature-lifecycle-cli.sh"
TEST_TMP="/tmp/aidev-lifecycle-roadmap-test-$$"

setup() {
    mkdir -p "$TEST_TMP/.aidev/plans/backlog"
    mkdir -p "$TEST_TMP/.aidev/plans/features"
    mkdir -p "$TEST_TMP/.aidev/plans/current"
    mkdir -p "$TEST_TMP/.aidev/plans/history/2026-02"
    mkdir -p "$TEST_TMP/.aidev/plans/history/2026-01"
    mkdir -p "$TEST_TMP/.aidev/lib"
    touch "$TEST_TMP/.aidev/.initialized"
    echo "4.5.5" > "$TEST_TMP/VERSION"

    # Feature ativa em current/
    echo "# Feature em Execucao" > "$TEST_TMP/.aidev/plans/current/feature-ativa.md"

    # Backlog com 2 itens
    cat > "$TEST_TMP/.aidev/plans/backlog/ideia-alta.md" <<'EOF'
# Ideia: Feature de Alta Prioridade
**Prioridade:** Alta
EOF
    cat > "$TEST_TMP/.aidev/plans/backlog/ideia-media.md" <<'EOF'
# Ideia: Feature de Media Prioridade
**Prioridade:** Media
EOF

    # History com features
    echo "# Feature Jan 1" > "$TEST_TMP/.aidev/plans/history/2026-01/feature-jan-1.md"
    echo "# Feature Jan 2" > "$TEST_TMP/.aidev/plans/history/2026-01/feature-jan-2.md"
    echo "# Feature Feb 1" > "$TEST_TMP/.aidev/plans/history/2026-02/feature-feb-1.md"

    cat > "$TEST_TMP/.aidev/plans/ROADMAP.md" <<'EOF'
# ROADMAP ANTIGO

Conteudo que deve ser substituido.
EOF
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Carrega o módulo para testes diretos
source "$FLC_MODULE" 2>/dev/null || true

# ============================================================================
# Sprint 5: ROADMAP tem no máximo 60 linhas
# ============================================================================

test_section "roadmap_rebuild: ROADMAP tem no maximo 60 linhas"

setup
(
    cd "$TEST_TMP"
    FLC_BACKLOG_DIR=".aidev/plans/backlog"
    FLC_FEATURES_DIR=".aidev/plans/features"
    FLC_CURRENT_DIR=".aidev/plans/current"
    FLC_HISTORY_DIR=".aidev/plans/history"
    FLC_ROADMAP=".aidev/plans/ROADMAP.md"
    source "$FLC_MODULE"
    _flc_roadmap_rebuild 2>/dev/null
)
local_lines=$(wc -l < "$TEST_TMP/.aidev/plans/ROADMAP.md")
[ "$local_lines" -le 60 ]
assert_equals "0" "$?" "ROADMAP tem no maximo 60 linhas (atual: $local_lines)"
teardown

# ============================================================================
# Sprint 5: ROADMAP menciona estrutura de pastas
# ============================================================================

test_section "roadmap_rebuild: menciona estrutura de pastas"

setup
(
    cd "$TEST_TMP"
    FLC_BACKLOG_DIR=".aidev/plans/backlog"
    FLC_FEATURES_DIR=".aidev/plans/features"
    FLC_CURRENT_DIR=".aidev/plans/current"
    FLC_HISTORY_DIR=".aidev/plans/history"
    FLC_ROADMAP=".aidev/plans/ROADMAP.md"
    source "$FLC_MODULE"
    _flc_roadmap_rebuild 2>/dev/null
)
grep -qi "backlog\|features\|current\|history" "$TEST_TMP/.aidev/plans/ROADMAP.md"
assert_equals "0" "$?" "ROADMAP menciona as 4 pastas do fluxo"
teardown

# ============================================================================
# Sprint 5: ROADMAP menciona feature ativa
# ============================================================================

test_section "roadmap_rebuild: menciona feature em execucao"

setup
(
    cd "$TEST_TMP"
    FLC_BACKLOG_DIR=".aidev/plans/backlog"
    FLC_FEATURES_DIR=".aidev/plans/features"
    FLC_CURRENT_DIR=".aidev/plans/current"
    FLC_HISTORY_DIR=".aidev/plans/history"
    FLC_ROADMAP=".aidev/plans/ROADMAP.md"
    source "$FLC_MODULE"
    _flc_roadmap_rebuild 2>/dev/null
)
grep -qi "feature.*ativa\|feature.*execucao\|feature-ativa\|Feature em Execucao" "$TEST_TMP/.aidev/plans/ROADMAP.md"
assert_equals "0" "$?" "ROADMAP menciona a feature em execucao"
teardown

# ============================================================================
# Sprint 5: ROADMAP tem links para history/
# ============================================================================

test_section "roadmap_rebuild: tem links para history/"

setup
(
    cd "$TEST_TMP"
    FLC_BACKLOG_DIR=".aidev/plans/backlog"
    FLC_FEATURES_DIR=".aidev/plans/features"
    FLC_CURRENT_DIR=".aidev/plans/current"
    FLC_HISTORY_DIR=".aidev/plans/history"
    FLC_ROADMAP=".aidev/plans/ROADMAP.md"
    source "$FLC_MODULE"
    _flc_roadmap_rebuild 2>/dev/null
)
grep -qi "history/2026\|history/" "$TEST_TMP/.aidev/plans/ROADMAP.md"
assert_equals "0" "$?" "ROADMAP tem links para pastas de history/"
teardown

# ============================================================================
# Sprint 5: ROADMAP menciona versão atual
# ============================================================================

test_section "roadmap_rebuild: menciona versao atual"

setup
(
    cd "$TEST_TMP"
    FLC_BACKLOG_DIR=".aidev/plans/backlog"
    FLC_FEATURES_DIR=".aidev/plans/features"
    FLC_CURRENT_DIR=".aidev/plans/current"
    FLC_HISTORY_DIR=".aidev/plans/history"
    FLC_ROADMAP=".aidev/plans/ROADMAP.md"
    source "$FLC_MODULE"
    _flc_roadmap_rebuild 2>/dev/null
)
grep -q "4.5.5" "$TEST_TMP/.aidev/plans/ROADMAP.md"
assert_equals "0" "$?" "ROADMAP menciona a versao do VERSION file"
teardown

# ============================================================================
# Sprint 5: orchestrator.md menciona comandos do lifecycle
# ============================================================================

test_section "orchestrator: menciona comandos do lifecycle"

ORCHESTRATOR="$ROOT_DIR/.aidev/agents/orchestrator.md"
grep -qi "aidev start\|aidev done\|aidev complete\|aidev plan\|lifecycle" "$ORCHESTRATOR" 2>/dev/null
assert_equals "0" "$?" "orchestrator.md menciona comandos de lifecycle"

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
