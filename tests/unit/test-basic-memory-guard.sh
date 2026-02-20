#!/bin/bash

# ============================================================================
# Testes Unitários - basic-memory-guard.sh
# Sprint 2: Guard Functions — Bash + LLM
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_LIB="$ROOT_DIR/.aidev/lib"
BM_GUARD="$AIDEV_LIB/basic-memory-guard.sh"
TEST_TMP="/tmp/aidev-bm-guard-test-$$"

# ============================================================================
# Setup / Teardown
# ============================================================================

setup() {
    mkdir -p "$TEST_TMP/.aidev/memory/kb"
    unset _AIDEV_BM_DETECTED
    unset BASIC_MEMORY_ENABLED
    unset MCP_BASIC_MEMORY_AVAILABLE
}

teardown() {
    rm -rf "$TEST_TMP"
    mkdir -p "$TEST_TMP/.aidev/memory/kb"
    unset _AIDEV_BM_DETECTED
    unset BASIC_MEMORY_ENABLED
    unset MCP_BASIC_MEMORY_AVAILABLE
}

assert_file_exists() {
    local file="$1" message="$2"
    if [ -f "$file" ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $message (não encontrado: $file)"
        ((TESTS_FAILED++))
    fi
}

assert_function_exists() {
    local fn="$1" message="$2"
    if type "$fn" &>/dev/null; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $message (função não encontrada: $fn)"
        ((TESTS_FAILED++))
    fi
}

# Carrega o módulo (deve existir para GREEN passar)
if [ -f "$BM_GUARD" ]; then
    source "$AIDEV_LIB/mcp-detect.sh" 2>/dev/null || true
    source "$BM_GUARD"
fi

# ============================================================================
# Existência do Módulo e Funções
# ============================================================================

test_section "basic-memory-guard: Existência do Módulo"

assert_file_exists "$BM_GUARD" "Arquivo .aidev/lib/basic-memory-guard.sh existe"
assert_function_exists "bm_write_note"  "Função bm_write_note existe"
assert_function_exists "bm_search"      "Função bm_search existe"
assert_function_exists "bm_build_context" "Função bm_build_context existe"
assert_function_exists "_bm_fallback_write"   "Função _bm_fallback_write existe"
assert_function_exists "_bm_fallback_search"  "Função _bm_fallback_search existe"
assert_function_exists "_bm_fallback_context" "Função _bm_fallback_context existe"

# ============================================================================
# Fallback de Escrita (sem Basic Memory)
# ============================================================================

test_section "basic-memory-guard: Fallback de Escrita"

setup
result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    bm_write_note "Titulo Teste" "Conteudo de teste" "kb"
    echo "exit:$?"
)
assert_equals "0" "$(echo "$result" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "bm_write_note sem BM retorna exit 0 (sem erro)"

# Verifica se o arquivo foi criado localmente
assert_file_exists "$TEST_TMP/.aidev/memory/kb/Titulo Teste.md" \
    "Fallback cria arquivo local em .aidev/memory/kb/"
teardown

# ============================================================================
# Fallback de Busca (sem Basic Memory)
# ============================================================================

test_section "basic-memory-guard: Fallback de Busca"

setup
# Cria uma nota local para buscar
mkdir -p "$TEST_TMP/.aidev/memory/kb"
echo "conteudo relevante para busca" > "$TEST_TMP/.aidev/memory/kb/nota-teste.md"

result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    bm_search "relevante"
    echo "exit:$?"
)
assert_equals "0" "$(echo "$result" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "bm_search sem BM retorna exit 0"
echo "$result" | grep -q "nota-teste"
assert_equals "0" "$?" "bm_search fallback encontra arquivo local com conteúdo relevante"
teardown

# ============================================================================
# Fallback de Contexto (sem Basic Memory)
# ============================================================================

test_section "basic-memory-guard: Fallback de Contexto"

setup
mkdir -p "$TEST_TMP/.aidev/state"
echo "# Checkpoint de teste" > "$TEST_TMP/.aidev/state/checkpoint.md"

result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    bm_build_context "memory://kb/*"
    echo "exit:$?"
)
assert_equals "0" "$(echo "$result" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "bm_build_context sem BM retorna exit 0"
teardown

# ============================================================================
# Zero erros sem Basic Memory (saídas não-zero proibidas)
# ============================================================================

test_section "basic-memory-guard: Zero Erros sem Basic Memory"

setup
(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    bm_write_note "Titulo" "Corpo"
    bm_search "query"
    bm_build_context "memory://kb/*"
) 2>/dev/null
assert_equals "0" "$?" "Todas as funções guard executam sem erros sem Basic Memory"
teardown

# ============================================================================
# Com Basic Memory disponível: não usa fallback
# ============================================================================

test_section "basic-memory-guard: Com Basic Memory — não cria arquivo local"

setup
# BASIC_MEMORY_ENABLED=true mas sem a função MCP real (ambiente de teste)
# O guard deve tentar chamar o MCP — não deve criar arquivo local
result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    # Stub da função MCP para o teste não falhar
    mcp__basic-memory__write_note() { echo "MCP_CALLED"; return 0; }
    BASIC_MEMORY_ENABLED=true bm_write_note "Titulo MCP" "Conteudo MCP" "kb"
    echo "exit:$?"
)
echo "$result" | grep -q "MCP_CALLED"
assert_equals "0" "$?" "Com BM disponível, bm_write_note chama o MCP real"
[ ! -f "$TEST_TMP/.aidev/memory/kb/Titulo MCP.md" ]
assert_equals "0" "$?" "Com BM disponível, não cria arquivo local de fallback"
teardown

# ============================================================================
# Camada B: Verificação de Guards nos .md
# ============================================================================

test_section "basic-memory-guard: Camada B — Guards nos .md"

AGENTS_DIR="$ROOT_DIR/.aidev/agents"
SKILLS_DIR="$ROOT_DIR/.aidev/skills"

# knowledge-manager.md deve ter seção de verificação de disponibilidade
grep -q "BASIC_MEMORY_AVAILABLE\|basic_memory_available\|mcp_detect" "$AGENTS_DIR/knowledge-manager.md" 2>/dev/null
assert_equals "0" "$?" "knowledge-manager.md tem verificação de disponibilidade do Basic Memory"

# learned-lesson/SKILL.md deve ter fallback
grep -q "BASIC_MEMORY_AVAILABLE\|basic_memory_available\|fallback\|sem.*Basic Memory\|Write tool" "$SKILLS_DIR/learned-lesson/SKILL.md" 2>/dev/null
assert_equals "0" "$?" "learned-lesson/SKILL.md tem instruções de fallback"

# systematic-debugging/SKILL.md deve ter fallback
grep -q "BASIC_MEMORY_AVAILABLE\|basic_memory_available\|fallback\|sem.*Basic Memory\|Write tool" "$SKILLS_DIR/systematic-debugging/SKILL.md" 2>/dev/null
assert_equals "0" "$?" "systematic-debugging/SKILL.md tem instruções de fallback"

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
