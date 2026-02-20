#!/bin/bash

# ============================================================================
# Testes Unitários - ckpt_sync_to_basic_memory
# Sprint 3: Checkpoint Sync Graceful
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

CKPT_MANAGER="$ROOT_DIR/lib/checkpoint-manager.sh"
TEST_TMP="/tmp/aidev-ckpt-sync-test-$$"

# Fixture: checkpoint JSON mínimo válido
FIXTURE_CKPT='{
  "checkpoint_id": "ckpt-sprint3-test",
  "trigger": "test",
  "description": "Checkpoint de teste Sprint 3",
  "sprint_id": "sprint-3",
  "sprint_name": "Sprint 3 Test",
  "current_task": "implementar ckpt_sync_to_basic_memory",
  "project_name": "aidev-superpowers-v3-1",
  "version": "4.5.5",
  "active_intent": "tdd",
  "progress": {"completed": 2, "total": 5},
  "timestamp": "2026-02-20T12:00:00Z"
}'

# ============================================================================
# Setup / Teardown
# ============================================================================

setup() {
    mkdir -p "$TEST_TMP/.aidev/state/sprints/current/checkpoints"
    mkdir -p "$TEST_TMP/.aidev/memory/kb/checkpoints"
    echo "$FIXTURE_CKPT" > "$TEST_TMP/.aidev/state/sprints/current/checkpoints/ckpt-sprint3-test.json"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
    unset CKPT_SYNC_BASIC_MEMORY
}

teardown() {
    rm -rf "$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED MCP_BASIC_MEMORY_AVAILABLE
    unset CKPT_SYNC_BASIC_MEMORY
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

# Carrega o módulo
source "$ROOT_DIR/.aidev/lib/mcp-detect.sh" 2>/dev/null || true
source "$CKPT_MANAGER" 2>/dev/null || true

# ============================================================================
# Existência da Função
# ============================================================================

test_section "ckpt_sync: Existência da Função"

assert_function_exists "ckpt_sync_to_basic_memory" "Função ckpt_sync_to_basic_memory existe"

# ============================================================================
# Fallback local (sem Basic Memory)
# ============================================================================

test_section "ckpt_sync: Fallback Local sem Basic Memory"

setup
FIXTURE_FILE="$TEST_TMP/.aidev/state/sprints/current/checkpoints/ckpt-sprint3-test.json"

result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    ckpt_sync_to_basic_memory "$FIXTURE_FILE"
    echo "exit:$?"
)
assert_equals "0" "$(echo "$result" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "ckpt_sync_to_basic_memory sem BM retorna exit 0 (não bloqueia)"

# Deve criar arquivo de fallback local
local_fallback=$(find "$TEST_TMP/.aidev/memory/kb/checkpoints" -name "*.md" 2>/dev/null | head -1)
[ -n "$local_fallback" ]
assert_equals "0" "$?" "Fallback cria arquivo .md em .aidev/memory/kb/checkpoints/"
teardown

# ============================================================================
# Com Basic Memory disponível: chama MCP
# ============================================================================

test_section "ckpt_sync: Com Basic Memory — usa MCP"

setup
FIXTURE_FILE="$TEST_TMP/.aidev/state/sprints/current/checkpoints/ckpt-sprint3-test.json"

result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    mcp__basic-memory__write_note() {
        echo "MCP_WRITE_CALLED:$*"
        return 0
    }
    BASIC_MEMORY_ENABLED=true ckpt_sync_to_basic_memory "$FIXTURE_FILE"
    echo "exit:$?"
)
echo "$result" | grep -q "MCP_WRITE_CALLED"
assert_equals "0" "$?" "Com BM disponível, ckpt_sync chama mcp__basic-memory__write_note"
assert_equals "0" "$(echo "$result" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "Com BM disponível retorna exit 0"
teardown

# ============================================================================
# Falha silenciosa: MCP falha, não bloqueia fluxo
# ============================================================================

test_section "ckpt_sync: Falha Silenciosa do MCP"

setup
FIXTURE_FILE="$TEST_TMP/.aidev/state/sprints/current/checkpoints/ckpt-sprint3-test.json"

result=$(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    mcp__basic-memory__write_note() { return 1; }  # Simula falha
    BASIC_MEMORY_ENABLED=true ckpt_sync_to_basic_memory "$FIXTURE_FILE"
    echo "exit:$?"
)
assert_equals "0" "$(echo "$result" | grep -o "exit:[0-9]" | cut -d: -f2)" \
    "Falha no MCP não propaga erro (sempre exit 0)"
teardown

# ============================================================================
# ckpt_create() delega para ckpt_sync_to_basic_memory
# ============================================================================

test_section "ckpt_sync: ckpt_create delega para ckpt_sync_to_basic_memory"

setup

# Verifica indiretamente: ckpt_create deve gerar o arquivo de fallback em .aidev/memory/kb/checkpoints/
# quando não há BM disponível — o que só acontece se chamar ckpt_sync_to_basic_memory
(
    cd "$TEST_TMP"
    CLI_INSTALL_PATH="$TEST_TMP"
    unset _AIDEV_BM_DETECTED BASIC_MEMORY_ENABLED
    ckpt_create "$TEST_TMP" "test_trigger" "Descricao de teste" 2>/dev/null
) || true

local_file=$(find "$TEST_TMP/.aidev/memory/kb/checkpoints" -name "*.md" 2>/dev/null | head -1)
[ -n "$local_file" ]
assert_equals "0" "$?" "ckpt_create gera fallback local via ckpt_sync_to_basic_memory"
teardown

# ============================================================================
# Arquivo inexistente: retorna sem erro
# ============================================================================

test_section "ckpt_sync: Arquivo Inexistente"

setup
(
    cd "$TEST_TMP"
    unset _AIDEV_BM_DETECTED
    ckpt_sync_to_basic_memory "/tmp/nao-existe-$$$.json"
    echo "exit:$?"
) | grep -q "exit:0"
assert_equals "0" "$?" "Arquivo inexistente retorna exit 0 (não bloqueia)"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
