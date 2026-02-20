#!/bin/bash

# ============================================================================
# Testes Unitários - mcp-detect.sh
# Sprint 1: Detecção Unificada Multi-Runtime
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"

# test_section pode não estar disponível fora do runner
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_LIB="$ROOT_DIR/.aidev/lib"
MCP_DETECT="$AIDEV_LIB/mcp-detect.sh"
TEST_TMP="/tmp/aidev-mcp-detect-test-$$"

# ============================================================================
# Setup / Teardown
# ============================================================================

setup() {
    mkdir -p "$TEST_TMP"
    # Limpa cache entre testes
    unset _AIDEV_BM_DETECTED
    unset BASIC_MEMORY_ENABLED
    unset MCP_BASIC_MEMORY_AVAILABLE
}

teardown() {
    rm -rf "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    unset BASIC_MEMORY_ENABLED
    unset MCP_BASIC_MEMORY_AVAILABLE
}

# Carrega o módulo (deve existir para GREEN passar)
if [ -f "$MCP_DETECT" ]; then
    source "$MCP_DETECT"
fi

# ============================================================================
# Testes de Existência do Módulo
# ============================================================================

test_section "mcp-detect: Existência do Módulo"

assert_file_exists() {
    local file="$1"
    local message="$2"
    if [ -f "$file" ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $message (arquivo não encontrado: $file)"
        ((TESTS_FAILED++))
    fi
}

assert_function_exists() {
    local fn="$1"
    local message="$2"
    if type "$fn" &>/dev/null; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $message (função não encontrada: $fn)"
        ((TESTS_FAILED++))
    fi
}

assert_file_exists "$MCP_DETECT" "Arquivo .aidev/lib/mcp-detect.sh existe"
assert_function_exists "mcp_detect_basic_memory" "Função mcp_detect_basic_memory existe"
assert_function_exists "mcp_detect_available" "Função mcp_detect_available existe"

# ============================================================================
# Testes de Detecção por Variável de Ambiente
# ============================================================================

test_section "mcp-detect: Camada 1 — Variável de Ambiente"

setup

BASIC_MEMORY_ENABLED=true mcp_detect_basic_memory
assert_equals "0" "$?" "BASIC_MEMORY_ENABLED=true retorna 0 (disponível)"
teardown

setup
MCP_BASIC_MEMORY_AVAILABLE=1 mcp_detect_basic_memory
assert_equals "0" "$?" "MCP_BASIC_MEMORY_AVAILABLE=1 retorna 0 (disponível)"
teardown

setup
# Isola em subshell sem .mcp.json e sem cache
result=$(cd "$TEST_TMP"; unset _AIDEV_BM_DETECTED; mcp_detect_basic_memory; echo $?)
assert_equals "1" "$result" "Sem variáveis retorna 1 (não disponível)"
teardown

# ============================================================================
# Testes de Detecção por .mcp.json
# ============================================================================

test_section "mcp-detect: Camada 2 — .mcp.json"

setup
# Cria .mcp.json com basic-memory no diretório temp
cat > "$TEST_TMP/.mcp.json" <<'EOF'
{
  "mcpServers": {
    "basic-memory": {
      "command": "uvx",
      "args": ["basic-memory", "mcp"]
    }
  }
}
EOF

# Simula runtime antigravity (MCPs expostos automaticamente)
(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    ANTIGRAVITY=1 mcp_detect_basic_memory
    echo "exit:$?"
) | grep -q "exit:0"
assert_equals "0" "$?" "Runtime antigravity com .mcp.json retorna 0"
teardown

setup
# Sem .mcp.json, sem variáveis
(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    mcp_detect_basic_memory
    echo "exit:$?"
) | grep -q "exit:1"
assert_equals "0" "$?" "Sem .mcp.json nem variáveis retorna 1"
teardown

# ============================================================================
# Testes de Cache
# ============================================================================

test_section "mcp-detect: Cache de Detecção"

setup
# Primeira chamada com BM disponível — seta cache
export BASIC_MEMORY_ENABLED=true
mcp_detect_basic_memory
first_result=$?

# Remove a variável — segunda chamada deve usar cache
unset BASIC_MEMORY_ENABLED
mcp_detect_basic_memory
second_result=$?

assert_equals "$first_result" "$second_result" "Segunda chamada usa cache (_AIDEV_BM_DETECTED)"
assert_equals "0" "${_AIDEV_BM_DETECTED:-nao_setado}" "Variável _AIDEV_BM_DETECTED é exportada"
teardown

# ============================================================================
# Testes de mcp_detect_available (genérica)
# ============================================================================

test_section "mcp-detect: mcp_detect_available (genérica)"

setup
cat > "$TEST_TMP/.mcp.json" <<'EOF'
{
  "mcpServers": {
    "basic-memory": {},
    "github": {}
  }
}
EOF

(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    ANTIGRAVITY=1 mcp_detect_available "basic-memory"
    echo "exit:$?"
) | grep -q "exit:0"
assert_equals "0" "$?" "mcp_detect_available('basic-memory') com .mcp.json retorna 0"

(
    cd "$TEST_TMP"
    mcp_detect_available "nao-existe-mcp"
    echo "exit:$?"
) | grep -q "exit:1"
assert_equals "0" "$?" "mcp_detect_available('nao-existe-mcp') retorna 1"
teardown

# ============================================================================
# Testes de Runtime Gemini/OpenCode (sem basic-memory CLI)
# ============================================================================

test_section "mcp-detect: Runtime Gemini/OpenCode sem CLI"

setup
cat > "$TEST_TMP/.mcp.json" <<'EOF'
{"mcpServers": {"basic-memory": {}}}
EOF

# Simula Gemini sem basic-memory instalado no PATH
(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    # OPENCODE=1 sinaliza runtime opencode
    # PATH reduzido para garantir que basic-memory não seja encontrado
    OPENCODE=1 PATH="/usr/bin:/bin" mcp_detect_basic_memory
    echo "exit:$?"
) | grep -q "exit:1"
assert_equals "0" "$?" "Runtime opencode sem CLI basic-memory retorna 1"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
