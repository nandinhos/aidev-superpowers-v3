#!/bin/bash

# ============================================================================
# Testes Unitarios: Context Monitor
# ============================================================================
# Testa funcoes de monitoramento de janela de contexto
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Carrega test framework
source "$PROJECT_ROOT/tests/helpers/test-framework.sh"

# Setup: cria diretorio temporario para testes
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

setup_test_env() {
    rm -rf "$TEST_DIR"
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.aidev/state/sprints/current"
    mkdir -p "$TEST_DIR/.aidev/state"

    # Cria unified.json minimo
    cat > "$TEST_DIR/.aidev/state/unified.json" << 'UNIFIED'
{
  "version": "3.9.0",
  "session": {
    "id": "test-session",
    "started_at": "2026-02-11T23:00:00Z"
  },
  "active_agent": "orchestrator"
}
UNIFIED
}

# Carrega modulo sob teste
source "$PROJECT_ROOT/lib/context-monitor.sh"

# ============================================================================
# TESTES: ctx_estimate_tokens
# ============================================================================

test_estimate_tokens_from_string() {
    setup_test_env
    local tokens=$(ctx_estimate_tokens "Hello world, this is a test string.")
    # ~34 chars / 4 = ~8-9 tokens
    [ "$tokens" -gt 0 ]
    assert_true $? "ctx_estimate_tokens retorna valor positivo para string"
}

test_estimate_tokens_empty_string() {
    setup_test_env
    local tokens=$(ctx_estimate_tokens "")
    assert_equals "0" "$tokens" "ctx_estimate_tokens retorna 0 para string vazia"
}

test_estimate_tokens_from_file() {
    setup_test_env
    echo "This is test content with multiple words for token estimation" > "$TEST_DIR/test-file.txt"
    local tokens=$(ctx_estimate_tokens_file "$TEST_DIR/test-file.txt")
    [ "$tokens" -gt 0 ]
    assert_true $? "ctx_estimate_tokens_file retorna valor positivo para arquivo"
}

test_estimate_tokens_file_not_found() {
    setup_test_env
    local tokens=$(ctx_estimate_tokens_file "$TEST_DIR/nao-existe.txt")
    assert_equals "0" "$tokens" "ctx_estimate_tokens_file retorna 0 para arquivo inexistente"
}

# ============================================================================
# TESTES: ctx_get_usage_percent
# ============================================================================

test_get_usage_percent_basic() {
    setup_test_env
    local percent=$(ctx_get_usage_percent 50000 200000)
    assert_equals "25" "$percent" "50k/200k = 25%"
}

test_get_usage_percent_full() {
    setup_test_env
    local percent=$(ctx_get_usage_percent 200000 200000)
    assert_equals "100" "$percent" "200k/200k = 100%"
}

test_get_usage_percent_zero() {
    setup_test_env
    local percent=$(ctx_get_usage_percent 0 200000)
    assert_equals "0" "$percent" "0/200k = 0%"
}

test_get_usage_percent_zero_max() {
    setup_test_env
    local percent=$(ctx_get_usage_percent 1000 0)
    assert_equals "100" "$percent" "Retorna 100 se max_tokens = 0 (safety)"
}

# ============================================================================
# TESTES: ctx_should_checkpoint
# ============================================================================

test_should_checkpoint_below_threshold() {
    setup_test_env
    local result=$(ctx_should_checkpoint 50)
    assert_equals "none" "$result" "50% nao deve gerar checkpoint"
}

test_should_checkpoint_warning_threshold() {
    setup_test_env
    local result=$(ctx_should_checkpoint 72)
    assert_equals "warning" "$result" "72% deve gerar warning"
}

test_should_checkpoint_auto_threshold() {
    setup_test_env
    local result=$(ctx_should_checkpoint 87)
    assert_equals "auto_checkpoint" "$result" "87% deve gerar auto_checkpoint"
}

test_should_checkpoint_force_threshold() {
    setup_test_env
    local result=$(ctx_should_checkpoint 96)
    assert_equals "force_save" "$result" "96% deve gerar force_save"
}

# ============================================================================
# TESTES: ctx_get_remaining_capacity
# ============================================================================

test_get_remaining_capacity() {
    setup_test_env
    local remaining=$(ctx_get_remaining_capacity 120000 200000)
    assert_equals "80000" "$remaining" "200k - 120k = 80k tokens restantes"
}

test_get_remaining_capacity_overflow() {
    setup_test_env
    local remaining=$(ctx_get_remaining_capacity 250000 200000)
    assert_equals "0" "$remaining" "Retorna 0 se usage > max (nao negativo)"
}

# ============================================================================
# TESTES: ctx_format_status
# ============================================================================

test_format_status_safe() {
    setup_test_env
    local status=$(ctx_format_status 30)
    assert_contains "$status" "SAFE" "30% deve mostrar SAFE"
}

test_format_status_warning() {
    setup_test_env
    local status=$(ctx_format_status 75)
    assert_contains "$status" "WARNING" "75% deve mostrar WARNING"
}

test_format_status_critical() {
    setup_test_env
    local status=$(ctx_format_status 90)
    assert_contains "$status" "CRITICAL" "90% deve mostrar CRITICAL"
}

test_format_status_emergency() {
    setup_test_env
    local status=$(ctx_format_status 96)
    assert_contains "$status" "EMERGENCY" "96% deve mostrar EMERGENCY"
}

# ============================================================================
# TESTES: ctx_update_session_metrics
# ============================================================================

test_update_session_metrics_writes_to_sprint() {
    setup_test_env

    cat > "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json" << 'SPRINT'
{
  "sprint_id": "sprint-3-test",
  "session_context": {
    "tokens_used_in_sprint": 0,
    "checkpoints_created": 0,
    "sessions_count": 1
  }
}
SPRINT

    ctx_update_session_metrics "$TEST_DIR" 50000
    local tokens_used=$(jq -r '.session_context.tokens_used_in_sprint' "$TEST_DIR/.aidev/state/sprints/current/sprint-status.json")

    assert_equals "50000" "$tokens_used" "Atualiza tokens_used_in_sprint no sprint-status.json"
}

# ============================================================================
# TESTES: ctx_get_thresholds
# ============================================================================

test_get_thresholds_returns_defaults() {
    setup_test_env
    local warning=$(ctx_get_threshold "warning")
    local auto=$(ctx_get_threshold "auto_checkpoint")
    local force=$(ctx_get_threshold "force_save")

    assert_equals "70" "$warning" "Threshold warning padrao = 70"
    assert_equals "85" "$auto" "Threshold auto_checkpoint padrao = 85"
    assert_equals "95" "$force" "Threshold force_save padrao = 95"
}

# ============================================================================
# EXECUCAO
# ============================================================================

run_test_suite "Context Monitor" \
    test_estimate_tokens_from_string \
    test_estimate_tokens_empty_string \
    test_estimate_tokens_from_file \
    test_estimate_tokens_file_not_found \
    test_get_usage_percent_basic \
    test_get_usage_percent_full \
    test_get_usage_percent_zero \
    test_get_usage_percent_zero_max \
    test_should_checkpoint_below_threshold \
    test_should_checkpoint_warning_threshold \
    test_should_checkpoint_auto_threshold \
    test_should_checkpoint_force_threshold \
    test_get_remaining_capacity \
    test_get_remaining_capacity_overflow \
    test_format_status_safe \
    test_format_status_warning \
    test_format_status_critical \
    test_format_status_emergency \
    test_update_session_metrics_writes_to_sprint \
    test_get_thresholds_returns_defaults
