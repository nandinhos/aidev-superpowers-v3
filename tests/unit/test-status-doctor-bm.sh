#!/bin/bash

# ============================================================================
# Testes Unitários - cmd_status e cmd_doctor com Basic Memory
# Sprint 5: Dashboard e Documentação
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
TEST_TMP="/tmp/aidev-status-doctor-test-$$"

# ============================================================================
# Setup / Teardown
# ============================================================================

setup() {
    mkdir -p "$TEST_TMP/.aidev/state"
    mkdir -p "$TEST_TMP/.aidev/agents"
    mkdir -p "$TEST_TMP/.aidev/skills"
    mkdir -p "$TEST_TMP/.aidev/rules"
    mkdir -p "$TEST_TMP/.aidev/memory/kb"
    mkdir -p "$TEST_TMP/.aidev/lib"
    # Copia mcp-detect.sh para simular instalação real
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
}

teardown() {
    rm -rf "$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
}

# ============================================================================
# cmd_status: exibe seção de integrações MCP
# ============================================================================

test_section "cmd_status: Integracoes MCP"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    bash "$AIDEV_BIN" status 2>/dev/null
)
echo "$output" | grep -qi "integr\|MCP\|basic.memory\|Basic Memory"
assert_equals "0" "$?" "cmd_status exibe seção de integrações MCP"
teardown

# ============================================================================
# cmd_status: Basic Memory indisponível exibe status correto
# ============================================================================

test_section "cmd_status: Basic Memory indisponível"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED
    bash "$AIDEV_BIN" status 2>/dev/null
)
echo "$output" | grep -qi "basic.memory\|Basic Memory"
assert_equals "0" "$?" "cmd_status menciona Basic Memory mesmo quando indisponível"
teardown

# ============================================================================
# cmd_status: Basic Memory disponível exibe 'ativo'
# ============================================================================

test_section "cmd_status: Basic Memory disponível"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    BASIC_MEMORY_ENABLED=true bash "$AIDEV_BIN" status 2>/dev/null
)
echo "$output" | grep -qi "ativo\|ativa\|disponivel\|available\|basic.memory.*true"
assert_equals "0" "$?" "cmd_status indica Basic Memory ativo quando disponível"
teardown

# ============================================================================
# cmd_doctor: diagnostica Basic Memory
# ============================================================================

test_section "cmd_doctor: Diagnóstico Basic Memory"

setup
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED
    bash "$AIDEV_BIN" doctor 2>/dev/null
)
echo "$output" | grep -qi "basic.memory\|Basic Memory"
assert_equals "0" "$?" "cmd_doctor menciona Basic Memory no diagnóstico"
teardown

# ============================================================================
# cmd_doctor: sugere instalação quando BM ausente
# ============================================================================

test_section "cmd_doctor: Sugere Basic Memory quando ausente"

setup
# Garante que não há BM disponível
output=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
    bash "$AIDEV_BIN" doctor 2>/dev/null
)
echo "$output" | grep -qi "instale\|install\|recomend\|pip\|pipx\|uvx\|opcional"
assert_equals "0" "$?" "cmd_doctor sugere como instalar Basic Memory quando ausente"
teardown

# ============================================================================
# QUICKSTART.md: tem seção de Basic Memory
# ============================================================================

test_section "QUICKSTART: Seção Basic Memory"

assert_file_has_content() {
    local file="$1" pattern="$2" message="$3"
    grep -qi "$pattern" "$file" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $message (padrão '$pattern' não encontrado em $file)"
        ((TESTS_FAILED++))
    fi
}

QUICKSTART="$ROOT_DIR/.aidev/QUICKSTART.md"
assert_file_has_content "$QUICKSTART" "basic.memory\|Basic Memory" \
    "QUICKSTART.md tem seção sobre Basic Memory"
assert_file_has_content "$QUICKSTART" "pip\|pipx\|uvx\|instalar\|install" \
    "QUICKSTART.md tem instruções de instalação do Basic Memory"
assert_file_has_content "$QUICKSTART" "opcional\|opcional.*recomend\|recomend" \
    "QUICKSTART.md indica que Basic Memory é opcional mas recomendado"

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
