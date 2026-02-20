#!/bin/bash

# ============================================================================
# Testes Unitários - context-window-monitor
# Sprint 1: indicador de pressão de contexto em aidev status
# Sprint 2: comando aidev checkpoint
# TDD RED PHASE
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

AIDEV_BIN="$ROOT_DIR/bin/aidev"
TEST_TMP="/tmp/aidev-ctxmonitor-test-$$"

setup() {
    mkdir -p "$TEST_TMP/.aidev/state"
    mkdir -p "$TEST_TMP/.aidev/lib"
    cp "$ROOT_DIR/.aidev/lib/mcp-detect.sh" "$TEST_TMP/.aidev/lib/" 2>/dev/null || true
    touch "$TEST_TMP/.aidev/.initialized"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ============================================================================
# Sprint 1: aidev status mostra secao de Janela de Contexto
# ============================================================================

test_section "cmd_status: exibe secao Janela de Contexto"

setup
# Cria context-log.json com 5 entradas (abaixo do threshold)
cat > "$TEST_TMP/.aidev/state/context-log.json" <<'EOF'
{
  "entries": [
    {"ts": "2026-02-20T10:00:00Z", "action": "start_task"},
    {"ts": "2026-02-20T10:01:00Z", "action": "edit_file"},
    {"ts": "2026-02-20T10:02:00Z", "action": "run_test"},
    {"ts": "2026-02-20T10:03:00Z", "action": "commit"},
    {"ts": "2026-02-20T10:04:00Z", "action": "end_task"}
  ]
}
EOF
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" status 2>/dev/null
)
echo "$result" | grep -qi "contexto\|context"
assert_equals "0" "$?" "aidev status exibe secao relacionada a contexto"
teardown

# ============================================================================
# Sprint 1: sessao longa (>20 eventos) exibe aviso
# ============================================================================

test_section "cmd_status: sessao longa (>20 eventos) exibe aviso"

setup
# Cria context-log.json com 25 entradas (acima do threshold de 20)
entries='{"entries":['
for i in $(seq 1 25); do
    entries+='{"ts":"2026-02-20T10:00:00Z","action":"event_'$i'"},'
done
entries="${entries%,}]}"
echo "$entries" > "$TEST_TMP/.aidev/state/context-log.json"

result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" status 2>/dev/null
)
echo "$result" | grep -qi "checkpoint\|sessao longa\|longa\|nova conversa\|nova sessao"
assert_equals "0" "$?" "aidev status avisa sobre sessao longa com >20 eventos"
teardown

# ============================================================================
# Sprint 1: sessao curta (<20 eventos) NAO exibe aviso de urgencia
# ============================================================================

test_section "cmd_status: sessao curta (<20 eventos) nao exibe aviso"

setup
cat > "$TEST_TMP/.aidev/state/context-log.json" <<'EOF'
{"entries":[
  {"ts":"2026-02-20T10:00:00Z","action":"a"},
  {"ts":"2026-02-20T10:01:00Z","action":"b"},
  {"ts":"2026-02-20T10:02:00Z","action":"c"}
]}
EOF
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" status 2>/dev/null
)
echo "$result" | grep -qi "ALERTA\|URGENTE\|CRITICO\|nova sessao agora"
assert_equals "1" "$?" "aidev status nao exibe alerta urgente para sessao curta"
teardown

# ============================================================================
# Sprint 1: sem context-log.json, status nao quebra
# ============================================================================

test_section "cmd_status: funciona sem context-log.json"

setup
# Nao cria context-log.json
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" status 2>/dev/null
    echo "exit:$?"
)
echo "$result" | grep -q "exit:0"
assert_equals "0" "$?" "aidev status nao quebra sem context-log.json"
teardown

# ============================================================================
# Sprint 2: aidev checkpoint existe como comando
# ============================================================================

test_section "cmd_checkpoint: comando existe e responde"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" checkpoint 2>&1
    echo "exit:$?"
)
# Nao deve retornar "comando nao reconhecido" ou "unknown command"
echo "$result" | grep -qi "nao reconhecido\|unknown command\|invalid\|not found"
assert_equals "1" "$?" "aidev checkpoint nao retorna erro de comando nao reconhecido"
teardown

# ============================================================================
# Sprint 2: aidev checkpoint cria arquivo checkpoint.md
# ============================================================================

test_section "cmd_checkpoint: cria checkpoint.md em .aidev/state/"

setup
(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" checkpoint 2>/dev/null
)
[ -f "$TEST_TMP/.aidev/state/checkpoint.md" ]
assert_equals "0" "$?" "aidev checkpoint cria .aidev/state/checkpoint.md"
teardown

# ============================================================================
# Sprint 2: aidev checkpoint exibe mensagem de confirmacao
# ============================================================================

test_section "cmd_checkpoint: exibe mensagem de sucesso"

setup
result=$(
    cd "$TEST_TMP"
    AIDEV_ROOT=".aidev" bash "$AIDEV_BIN" checkpoint 2>&1
)
echo "$result" | grep -qi "checkpoint\|criado\|salvo\|gravado"
assert_equals "0" "$?" "aidev checkpoint exibe mensagem de confirmacao"
teardown

# ============================================================================
# Resumo
# ============================================================================

echo ""
echo "============================================================"
echo "  Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "============================================================"

[ "$TESTS_FAILED" -eq 0 ]
