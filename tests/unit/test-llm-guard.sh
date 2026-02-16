#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - LLM Guard Tests (TDD RED Phase)
# ============================================================================
# Testes para o modulo de guardrails de execucao LLM
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source modules under test
if [ -f "$ROOT_DIR/lib/core.sh" ]; then
    source "$ROOT_DIR/lib/core.sh"
fi
if [ -f "$ROOT_DIR/lib/file-ops.sh" ]; then
    source "$ROOT_DIR/lib/file-ops.sh"
fi
if [ -f "$ROOT_DIR/lib/manifest.sh" ]; then
    source "$ROOT_DIR/lib/manifest.sh"
fi
if [ -f "$ROOT_DIR/lib/state.sh" ]; then
    source "$ROOT_DIR/lib/state.sh"
fi
if [ -f "$ROOT_DIR/lib/llm-guard.sh" ]; then
    source "$ROOT_DIR/lib/llm-guard.sh"
fi

# ============================================================================
# Test Setup
# ============================================================================

TEST_TEMP_DIR=""

setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    # Copiar MANIFEST.json para o temp dir
    if [ -f "$ROOT_DIR/MANIFEST.json" ]; then
        cp "$ROOT_DIR/MANIFEST.json" "$TEST_TEMP_DIR/MANIFEST.json"
    fi
    # Configurar manifesto
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_load 2>/dev/null || true
    # Criar diretorio de estado
    mkdir -p "$TEST_TEMP_DIR/.aidev/state"
    mkdir -p "$TEST_TEMP_DIR/.aidev/rules"
    CLI_INSTALL_PATH="$TEST_TEMP_DIR"
}

teardown_test_env() {
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ============================================================================
# Tests: Funcoes existem
# ============================================================================

test_section "llm-guard - Funcoes existem"

if type llm_guard_validate_scope &>/dev/null; then
    assert_equals "0" "0" "llm_guard_validate_scope funcao existe"
else
    assert_equals "0" "1" "llm_guard_validate_scope funcao existe"
fi

if type llm_guard_enforce_limits &>/dev/null; then
    assert_equals "0" "0" "llm_guard_enforce_limits funcao existe"
else
    assert_equals "0" "1" "llm_guard_enforce_limits funcao existe"
fi

if type llm_guard_log_decision &>/dev/null; then
    assert_equals "0" "0" "llm_guard_log_decision funcao existe"
else
    assert_equals "0" "1" "llm_guard_log_decision funcao existe"
fi

if type llm_guard_pre_check &>/dev/null; then
    assert_equals "0" "0" "llm_guard_pre_check funcao existe"
else
    assert_equals "0" "1" "llm_guard_pre_check funcao existe"
fi

if type llm_guard_audit &>/dev/null; then
    assert_equals "0" "0" "llm_guard_audit funcao existe"
else
    assert_equals "0" "1" "llm_guard_audit funcao existe"
fi

# ============================================================================
# Tests: llm_guard_validate_scope
# ============================================================================

test_section "llm_guard_validate_scope - Validacao de escopo"

setup_test_env
if type llm_guard_validate_scope &>/dev/null; then
    # Test: rejeita modificacao em arquivo core (bin/aidev)
    llm_guard_validate_scope '["bin/aidev"]' 2>/dev/null
    assert_equals "1" "$?" "rejeita modificacao em bin/aidev (core)"

    # Test: rejeita modificacao em arquivo core (lib/*.sh)
    llm_guard_validate_scope '["lib/core.sh"]' 2>/dev/null
    assert_equals "1" "$?" "rejeita modificacao em lib/core.sh (core)"

    # Test: rejeita modificacao em arquivo state
    llm_guard_validate_scope '[".aidev/state/unified.json"]' 2>/dev/null
    assert_equals "1" "$?" "rejeita modificacao em state/unified.json"

    # Test: permite modificacao em arquivo user (plans)
    llm_guard_validate_scope '[".aidev/plans/feature.md"]' 2>/dev/null
    assert_equals "0" "$?" "permite modificacao em plans/ (user)"

    # Test: permite modificacao em arquivo template
    llm_guard_validate_scope '[".aidev/agents/orchestrator.md"]' 2>/dev/null
    assert_equals "0" "$?" "permite modificacao em agents/ (template)"

    # Test: permite modificacao em arquivo desconhecido
    llm_guard_validate_scope '["src/app.js"]' 2>/dev/null
    assert_equals "0" "$?" "permite modificacao em arquivo desconhecido"

    # Test: rejeita se qualquer arquivo no batch eh protegido
    llm_guard_validate_scope '["src/app.js", "bin/aidev"]' 2>/dev/null
    assert_equals "1" "$?" "rejeita batch se contiver arquivo core"

    # Test: aceita batch sem arquivos protegidos
    llm_guard_validate_scope '["src/app.js", ".aidev/plans/todo.md"]' 2>/dev/null
    assert_equals "0" "$?" "aceita batch sem arquivos protegidos"
else
    assert_equals "0" "1" "llm_guard_validate_scope nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: llm_guard_enforce_limits
# ============================================================================

test_section "llm_guard_enforce_limits - Enforcement de limites"

setup_test_env
if type llm_guard_enforce_limits &>/dev/null; then
    # Cria llm-limits.md com limites conhecidos
    cat > "$TEST_TEMP_DIR/.aidev/rules/llm-limits.md" << 'LIMITS'
# LLM Execution Limits

## Limits
- MAX_FILES_PER_CYCLE=5
- MAX_LINES_PER_FILE=100
LIMITS

    # Test: retorna limites corretos
    result=$(llm_guard_enforce_limits "$TEST_TEMP_DIR")
    assert_contains "$result" "MAX_FILES_PER_CYCLE=5" "extrai MAX_FILES_PER_CYCLE do arquivo"
    assert_contains "$result" "MAX_LINES_PER_FILE=100" "extrai MAX_LINES_PER_FILE do arquivo"

    # Test: retorna defaults quando arquivo nao existe
    rm -f "$TEST_TEMP_DIR/.aidev/rules/llm-limits.md"
    result=$(llm_guard_enforce_limits "$TEST_TEMP_DIR")
    assert_contains "$result" "MAX_FILES_PER_CYCLE=10" "retorna default MAX_FILES_PER_CYCLE=10"
    assert_contains "$result" "MAX_LINES_PER_FILE=200" "retorna default MAX_LINES_PER_FILE=200"
else
    assert_equals "0" "1" "llm_guard_enforce_limits nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: llm_guard_log_decision
# ============================================================================

test_section "llm_guard_log_decision - Log de decisoes"

setup_test_env
if type llm_guard_log_decision &>/dev/null; then
    # Test: log decision usa state_log_confidence
    llm_guard_log_decision "Modificar arquivo X" "Dentro do escopo" "0.9" 2>/dev/null
    # Verifica que confidence_log foi atualizado no state
    if [ -f "$TEST_TEMP_DIR/.aidev/state/unified.json" ] && command -v jq &>/dev/null; then
        count=$(jq '.confidence_log | length' "$TEST_TEMP_DIR/.aidev/state/unified.json" 2>/dev/null)
        result=$( [ "${count:-0}" -gt 0 ] && echo "logged" || echo "empty" )
        assert_equals "logged" "$result" "decisao registrada no confidence_log"
    else
        assert_equals "0" "0" "decisao registrada (sem jq para verificar)"
    fi
else
    assert_equals "0" "1" "llm_guard_log_decision nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: llm_guard_audit
# ============================================================================

test_section "llm_guard_audit - Auditoria"

setup_test_env
if type llm_guard_audit &>/dev/null; then
    # Test: cria entrada no audit.log
    llm_guard_audit "session-test-123" "modify" "allowed" 2>/dev/null
    if [ -f "$TEST_TEMP_DIR/.aidev/state/audit.log" ]; then
        assert_equals "0" "0" "audit.log criado"
        content=$(cat "$TEST_TEMP_DIR/.aidev/state/audit.log")
        assert_contains "$content" "session-test-123" "audit.log contem session_id"
        assert_contains "$content" "modify" "audit.log contem action"
        assert_contains "$content" "allowed" "audit.log contem result"
    else
        assert_equals "0" "1" "audit.log criado"
    fi

    # Test: append nao sobrescreve
    llm_guard_audit "session-test-456" "delete" "blocked" 2>/dev/null
    line_count=$(wc -l < "$TEST_TEMP_DIR/.aidev/state/audit.log")
    result=$( [ "$line_count" -ge 2 ] && echo "appended" || echo "overwritten" )
    assert_equals "appended" "$result" "audit.log faz append (nao sobrescreve)"
else
    assert_equals "0" "1" "llm_guard_audit nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: llm_guard_pre_check
# ============================================================================

test_section "llm_guard_pre_check - Gate unificado"

setup_test_env
if type llm_guard_pre_check &>/dev/null; then
    # Cria llm-limits.md com limites
    cat > "$TEST_TEMP_DIR/.aidev/rules/llm-limits.md" << 'LIMITS'
# LLM Execution Limits

## Limits
- MAX_FILES_PER_CYCLE=3
- MAX_LINES_PER_FILE=100
LIMITS

    # Test: pre_check permite acao valida
    llm_guard_pre_check "edit" '["src/app.js"]' 2>/dev/null
    assert_equals "0" "$?" "pre_check permite acao em arquivo nao-protegido"

    # Test: pre_check bloqueia acao em arquivo core
    llm_guard_pre_check "edit" '["bin/aidev"]' 2>/dev/null
    assert_equals "1" "$?" "pre_check bloqueia acao em arquivo core"

    # Test: pre_check bloqueia quando excede MAX_FILES_PER_CYCLE
    llm_guard_pre_check "edit" '["a.js","b.js","c.js","d.js"]' 2>/dev/null
    assert_equals "1" "$?" "pre_check bloqueia quando excede MAX_FILES (3)"

    # Test: pre_check permite dentro do limite
    llm_guard_pre_check "edit" '["a.js","b.js"]' 2>/dev/null
    assert_equals "0" "$?" "pre_check permite dentro do limite MAX_FILES"
else
    assert_equals "0" "1" "llm_guard_pre_check nao disponivel"
fi
teardown_test_env
