#!/bin/bash

# ============================================================================
# Testes Unitários - context_compressor_generate com Basic Memory
# Sprint 4: Contexto Inteligente na Ativação
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

COMPRESSOR="$ROOT_DIR/lib/context-compressor.sh"
TEST_TMP="/tmp/aidev-ctx-compressor-test-$$"

# Fixture: unified.json mínimo
FIXTURE_UNIFIED='{
  "version": "4.5.5",
  "sprint_context": {
    "sprint_name": "Sprint 4",
    "progress_percentage": 50,
    "current_task_id": "task-bm-integration"
  },
  "active_intent": "feature_request",
  "active_skill": "tdd"
}'

# ============================================================================
# Setup / Teardown
# ============================================================================

setup() {
    mkdir -p "$TEST_TMP/.aidev/state/sprints/current/checkpoints"
    mkdir -p "$TEST_TMP/.aidev/memory/kb"
    mkdir -p "$TEST_TMP/.aidev/.cache"
    echo "$FIXTURE_UNIFIED" > "$TEST_TMP/.aidev/state/unified.json"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
}

teardown() {
    rm -rf "$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
}

# Carrega o módulo
source "$ROOT_DIR/.aidev/lib/mcp-detect.sh" 2>/dev/null || true
source "$COMPRESSOR"

# ============================================================================
# Sem Regressão: output sem BM idêntico ao comportamento atual
# ============================================================================

test_section "context-compressor: Sem Regressão sem Basic Memory"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    context_compressor_generate ".aidev/.cache/activation_context.md" 2>/dev/null
    cat ".aidev/.cache/activation_context.md" 2>/dev/null
)
echo "$output" | grep -q "IDENTIDADE DO SISTEMA"
assert_equals "0" "$?" "Output sem BM mantém seção IDENTIDADE DO SISTEMA"

echo "$output" | grep -q "RESUMO EXECUTIVO"
assert_equals "0" "$?" "Output sem BM mantém seção RESUMO EXECUTIVO"

echo "$output" | grep -q "Sprint 4"
assert_equals "0" "$?" "Output sem BM exibe nome da sprint"
teardown

# ============================================================================
# Com Basic Memory: seção cross-session adicionada
# ============================================================================

test_section "context-compressor: Enriquecimento com Basic Memory"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    # Stub do MCP para simular busca com resultados
    mcp__basic-memory__search_notes() {
        echo "## Lição: NullPointer em JWT"
        echo "Causa: token expirado sem validação."
    }
    BASIC_MEMORY_ENABLED=true context_compressor_generate ".aidev/.cache/activation_context.md" 2>/dev/null
    cat ".aidev/.cache/activation_context.md" 2>/dev/null
)
echo "$output" | grep -qi "cross.session\|Basic Memory\|Memória\|Memoria"
assert_equals "0" "$?" "Com BM disponível, output tem seção de memória cross-session"
teardown

# ============================================================================
# Com Basic Memory: não quebra se MCP falhar
# ============================================================================

test_section "context-compressor: Falha Silenciosa do MCP"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    mcp__basic-memory__search_notes() { return 1; }  # Simula falha
    BASIC_MEMORY_ENABLED=true context_compressor_generate ".aidev/.cache/activation_context.md" 2>/dev/null
    echo "exit:$?"
    cat ".aidev/.cache/activation_context.md" 2>/dev/null
)
assert_equals "0" "$(echo "$output" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "Falha no MCP não bloqueia geração do contexto (sempre exit 0)"

echo "$output" | grep -q "IDENTIDADE DO SISTEMA"
assert_equals "0" "$?" "Mesmo com BM falhando, contexto base é gerado normalmente"
teardown

# ============================================================================
# Status do Basic Memory aparece no contexto gerado
# ============================================================================

test_section "context-compressor: Status BM no contexto"

setup
output_sem_bm=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    context_compressor_generate ".aidev/.cache/activation_context.md" 2>/dev/null
    cat ".aidev/.cache/activation_context.md"
)

# Com BM: deve mencionar disponibilidade
output_com_bm=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    mcp__basic-memory__search_notes() { echo "resultado stub"; }
    BASIC_MEMORY_ENABLED=true context_compressor_generate ".aidev/.cache/activation_context_bm.md" 2>/dev/null
    cat ".aidev/.cache/activation_context_bm.md"
)

echo "$output_com_bm" | grep -qi "basic.memory\|cross.session\|Memória\|Memoria"
assert_equals "0" "$?" "Contexto com BM menciona Basic Memory ou memória cross-session"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
