#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Context Monitor Tests
# ============================================================================
# Testes unitarios para o modulo context-monitor.sh
# TDD: RED phase - Escrever testes que falham
#
# Uso: ./test-context-monitor.sh
# ============================================================================

# Setup test environment
TEST_DIR="$(mktemp -d)"
export CLI_INSTALL_PATH="$TEST_DIR"

# Load test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
source "$ROOT_DIR/lib/context-monitor.sh"

# ============================================================================
# TESTES: ctx_estimate_tokens
# ============================================================================

test_ctx_estimate_tokens_empty() {
    local result=$(ctx_estimate_tokens "")
    assert_equals "0" "$result" "String vazia deve retornar 0 tokens"
}

test_ctx_estimate_tokens_short() {
    local result=$(ctx_estimate_tokens "hello")
    # 5 chars / 4 = 1.25 -> 1 token
    assert_equals "1" "$result" "String curta (5 chars) deve retornar 1 token"
}

test_ctx_estimate_tokens_medium() {
    local text="This is a test string with 40 chars!"
    local result=$(ctx_estimate_tokens "$text")
    # 38 chars / 4 = 9.5 -> 9 tokens
    assert_equals "9" "$result" "String media deve calcular tokens corretamente"
}

test_ctx_estimate_tokens_exact_boundary() {
    local text="1234"
    local result=$(ctx_estimate_tokens "$text")
    # 4 chars / 4 = 1 token (exact boundary)
    assert_equals "1" "$result" "Boundary exato (4 chars) deve retornar 1 token"
}

test_ctx_estimate_tokens_unicode() {
    local text="Olá mundo! 🚀"
    local result=$(ctx_estimate_tokens "$text")
    # Unicode chars count individually
    local char_count=${#text}
    local expected=$(( char_count / 4 ))
    if [ "$expected" -eq 0 ]; then
        expected=1
    fi
    assert_equals "$expected" "$result" "Unicode deve ser contado corretamente"
}

test_ctx_estimate_tokens_multiline() {
    local text="Line 1
Line 2
Line 3"
    local result=$(ctx_estimate_tokens "$text")
    local char_count=${#text}
    local expected=$(( char_count / 4 ))
    assert_equals "$expected" "$result" "Texto multiline deve calcular tokens"
}

# ============================================================================
# TESTES: ctx_estimate_tokens_file
# ============================================================================

test_ctx_estimate_tokens_file_not_exists() {
    local result=$(ctx_estimate_tokens_file "/nonexistent/file.txt")
    assert_equals "0" "$result" "Arquivo inexistente deve retornar 0 tokens"
}

test_ctx_estimate_tokens_file_empty() {
    local test_file="$TEST_DIR/empty.txt"
    touch "$test_file"
    local result=$(ctx_estimate_tokens_file "$test_file")
    assert_equals "0" "$result" "Arquivo vazio deve retornar 0 tokens"
}

test_ctx_estimate_tokens_file_with_content() {
    local test_file="$TEST_DIR/test.txt"
    echo "This is test content with 45 characters!" > "$test_file"
    local result=$(ctx_estimate_tokens_file "$test_file")
    # 42 chars / 4 = 10.5 -> 10 tokens
    assert_equals "10" "$result" "Arquivo com conteudo deve calcular tokens"
}

test_ctx_estimate_tokens_file_large() {
    local test_file="$TEST_DIR/large.txt"
    # Create file with 400 chars
    printf '%0.sX' {1..400} > "$test_file"
    local result=$(ctx_estimate_tokens_file "$test_file")
    # 400 chars / 4 = 100 tokens
    assert_equals "100" "$result" "Arquivo grande deve calcular tokens corretamente"
}

# ============================================================================
# TESTES: ctx_get_usage_percent
# ============================================================================

test_ctx_get_usage_percent_zero_max() {
    local result=$(ctx_get_usage_percent 100 0)
    assert_equals "100" "$result" "Max zero deve retornar 100%"
}

test_ctx_get_usage_percent_zero_used() {
    local result=$(ctx_get_usage_percent 0 1000)
    assert_equals "0" "$result" "Used zero deve retornar 0%"
}

test_ctx_get_usage_percent_50_percent() {
    local result=$(ctx_get_usage_percent 5000 10000)
    assert_equals "50" "$result" "5000/10000 deve ser 50%"
}

test_ctx_get_usage_percent_100_percent() {
    local result=$(ctx_get_usage_percent 10000 10000)
    assert_equals "100" "$result" "10000/10000 deve ser 100%"
}

test_ctx_get_usage_percent_over_100() {
    local result=$(ctx_get_usage_percent 15000 10000)
    assert_equals "100" "$result" "Over 100% deve ser clamped para 100%"
}

test_ctx_get_usage_percent_25_percent() {
    local result=$(ctx_get_usage_percent 2500 10000)
    assert_equals "25" "$result" "2500/10000 deve ser 25%"
}

test_ctx_get_usage_percent_75_percent() {
    local result=$(ctx_get_usage_percent 7500 10000)
    assert_equals "75" "$result" "7500/10000 deve ser 75%"
}

test_ctx_get_usage_percent_1_percent() {
    local result=$(ctx_get_usage_percent 100 10000)
    assert_equals "1" "$result" "100/10000 deve ser 1%"
}

test_ctx_get_usage_percent_99_percent() {
    local result=$(ctx_get_usage_percent 9900 10000)
    assert_equals "99" "$result" "9900/10000 deve ser 99%"
}

# ============================================================================
# TESTES: ctx_get_remaining_capacity
# ============================================================================

test_ctx_get_remaining_capacity_normal() {
    local result=$(ctx_get_remaining_capacity 3000 10000)
    assert_equals "7000" "$result" "10000-3000 deve ser 7000"
}

test_ctx_get_remaining_capacity_zero() {
    local result=$(ctx_get_remaining_capacity 0 10000)
    assert_equals "10000" "$result" "10000-0 deve ser 10000"
}

test_ctx_get_remaining_capacity_full() {
    local result=$(ctx_get_remaining_capacity 10000 10000)
    assert_equals "0" "$result" "10000-10000 deve ser 0"
}

test_ctx_get_remaining_capacity_over_limit() {
    local result=$(ctx_get_remaining_capacity 15000 10000)
    assert_equals "0" "$result" "Over limit deve retornar 0 (nao negativo)"
}

test_ctx_get_remaining_capacity_exact_boundary() {
    local result=$(ctx_get_remaining_capacity 9999 10000)
    assert_equals "1" "$result" "Boundary: 10000-9999 deve ser 1"
}

# ============================================================================
# TESTES: ctx_should_checkpoint
# ============================================================================

test_ctx_should_checkpoint_none() {
    local result=$(ctx_should_checkpoint 50)
    assert_equals "none" "$result" "50% deve retornar 'none'"
}

test_ctx_should_checkpoint_warning_boundary() {
    local result=$(ctx_should_checkpoint 70)
    assert_equals "warning" "$result" "70% (boundary) deve retornar 'warning'"
}

test_ctx_should_checkpoint_warning_above() {
    local result=$(ctx_should_checkpoint 75)
    assert_equals "warning" "$result" "75% deve retornar 'warning'"
}

test_ctx_should_checkpoint_auto_checkpoint_boundary() {
    local result=$(ctx_should_checkpoint 85)
    assert_equals "auto_checkpoint" "$result" "85% (boundary) deve retornar 'auto_checkpoint'"
}

test_ctx_should_checkpoint_auto_checkpoint_above() {
    local result=$(ctx_should_checkpoint 90)
    assert_equals "auto_checkpoint" "$result" "90% deve retornar 'auto_checkpoint'"
}

test_ctx_should_checkpoint_force_save_boundary() {
    local result=$(ctx_should_checkpoint 95)
    assert_equals "force_save" "$result" "95% (boundary) deve retornar 'force_save'"
}

test_ctx_should_checkpoint_force_save_above() {
    local result=$(ctx_should_checkpoint 99)
    assert_equals "force_save" "$result" "99% deve retornar 'force_save'"
}

test_ctx_should_checkpoint_zero() {
    local result=$(ctx_should_checkpoint 0)
    assert_equals "none" "$result" "0% deve retornar 'none'"
}

test_ctx_should_checkpoint_69_percent() {
    local result=$(ctx_should_checkpoint 69)
    assert_equals "none" "$result" "69% (just below warning) deve retornar 'none'"
}

test_ctx_should_checkpoint_84_percent() {
    local result=$(ctx_should_checkpoint 84)
    assert_equals "warning" "$result" "84% (just below auto) deve retornar 'warning'"
}

test_ctx_should_checkpoint_94_percent() {
    local result=$(ctx_should_checkpoint 94)
    assert_equals "auto_checkpoint" "$result" "94% (just below force) deve retornar 'auto_checkpoint'"
}

# ============================================================================
# TESTES: ctx_get_threshold
# ============================================================================

test_ctx_get_threshold_warning() {
    local result=$(ctx_get_threshold "warning")
    assert_equals "70" "$result" "Threshold 'warning' deve ser 70"
}

test_ctx_get_threshold_auto_checkpoint() {
    local result=$(ctx_get_threshold "auto_checkpoint")
    assert_equals "85" "$result" "Threshold 'auto_checkpoint' deve ser 85"
}

test_ctx_get_threshold_force_save() {
    local result=$(ctx_get_threshold "force_save")
    assert_equals "95" "$result" "Threshold 'force_save' deve ser 95"
}

test_ctx_get_threshold_invalid() {
    local result=$(ctx_get_threshold "invalid")
    assert_equals "0" "$result" "Threshold invalido deve retornar 0"
}

test_ctx_get_threshold_empty() {
    local result=$(ctx_get_threshold "")
    assert_equals "0" "$result" "Threshold vazio deve retornar 0"
}

# ============================================================================
# TESTES: ctx_format_status
# ============================================================================

test_ctx_format_status_safe() {
    local result=$(ctx_format_status 50)
    assert_contains "$result" "[SAFE]" "50% deve mostrar [SAFE]"
    assert_contains "$result" "50%" "50% deve incluir percentual"
}

test_ctx_format_status_warning() {
    local result=$(ctx_format_status 75)
    assert_contains "$result" "[WARNING]" "75% deve mostrar [WARNING]"
    assert_contains "$result" "75%" "75% deve incluir percentual"
}

test_ctx_format_status_critical() {
    local result=$(ctx_format_status 90)
    assert_contains "$result" "[CRITICAL]" "90% deve mostrar [CRITICAL]"
    assert_contains "$result" "90%" "90% deve incluir percentual"
}

test_ctx_format_status_emergency() {
    local result=$(ctx_format_status 98)
    assert_contains "$result" "[EMERGENCY]" "98% deve mostrar [EMERGENCY]"
    assert_contains "$result" "98%" "98% deve incluir percentual"
}

test_ctx_format_status_boundary_safe() {
    local result=$(ctx_format_status 69)
    assert_contains "$result" "[SAFE]" "69% deve mostrar [SAFE]"
}

test_ctx_format_status_boundary_warning() {
    local result=$(ctx_format_status 70)
    assert_contains "$result" "[WARNING]" "70% (boundary) deve mostrar [WARNING]"
}

test_ctx_format_status_zero() {
    local result=$(ctx_format_status 0)
    assert_contains "$result" "[SAFE]" "0% deve mostrar [SAFE]"
}

test_ctx_format_status_100() {
    local result=$(ctx_format_status 100)
    assert_contains "$result" "[EMERGENCY]" "100% deve mostrar [EMERGENCY]"
}

# ============================================================================
# TESTES: ctx_update_session_metrics
# ============================================================================

test_ctx_update_session_metrics_success() {
    # Create test sprint-status.json
    local sprint_file="$TEST_DIR/.aidev/state/sprints/current/sprint-status.json"
    ensure_dir "$(dirname "$sprint_file")"
    
    cat > "$sprint_file" << 'EOF'
{
  "sprint_id": "test-sprint",
  "session_context": {
    "tokens_used_in_sprint": 0
  }
}
EOF
    
    ctx_update_session_metrics "$TEST_DIR" 5000
    
    if command -v jq >/dev/null 2>&1; then
        local result=$(jq -r '.session_context.tokens_used_in_sprint' "$sprint_file")
        assert_equals "5000" "$result" "Deve atualizar tokens_used_in_sprint para 5000"
    else
        echo "⚠️  SKIP: jq nao disponivel"
        ((TESTS_PASSED++))
    fi
}

test_ctx_update_session_metrics_file_not_exists() {
    local result=$(ctx_update_session_metrics "$TEST_DIR/nonexistent" 1000)
    # Should return 1 (failure) but function doesn't return explicit code
    # Just verify it doesn't crash
    assert_equals "" "$result" "Arquivo inexistente nao deve gerar output"
}

# ============================================================================
# TESTES: Variaveis de ambiente
# ============================================================================

test_custom_thresholds() {
    # Save original values
    local orig_warning=$CTX_THRESHOLD_WARNING
    local orig_auto=$CTX_THRESHOLD_AUTO_CHECKPOINT
    local orig_force=$CTX_THRESHOLD_FORCE_SAVE
    
    # Set custom thresholds
    export CTX_THRESHOLD_WARNING=60
    export CTX_THRESHOLD_AUTO_CHECKPOINT=80
    export CTX_THRESHOLD_FORCE_SAVE=90
    
    # Reload module to pick up new values
    source "$ROOT_DIR/lib/context-monitor.sh"
    
    # Test with new thresholds
    local result=$(ctx_should_checkpoint 65)
    assert_equals "warning" "$result" "Custom threshold: 65% com warning=60 deve retornar warning"
    
    result=$(ctx_should_checkpoint 85)
    assert_equals "auto_checkpoint" "$result" "Custom threshold: 85% com auto=80 deve retornar auto_checkpoint"
    
    # Restore original values
    export CTX_THRESHOLD_WARNING=$orig_warning
    export CTX_THRESHOLD_AUTO_CHECKPOINT=$orig_auto
    export CTX_THRESHOLD_FORCE_SAVE=$orig_force
    
    # Reload again
    source "$ROOT_DIR/lib/context-monitor.sh"
}

test_custom_chars_per_token() {
    # Save original
    local orig=$CTX_CHARS_PER_TOKEN
    
    # Set custom ratio
    export CTX_CHARS_PER_TOKEN=3
    source "$ROOT_DIR/lib/context-monitor.sh"
    
    local result=$(ctx_estimate_tokens "123456")
    # 6 chars / 3 = 2 tokens
    assert_equals "2" "$result" "Custom ratio: 6 chars / 3 = 2 tokens"
    
    # Restore
    export CTX_CHARS_PER_TOKEN=$orig
    source "$ROOT_DIR/lib/context-monitor.sh"
}

# ============================================================================
# TESTES: Casos de borda e stress
# ============================================================================

test_ctx_estimate_tokens_very_long() {
    # Create string with 10000 chars
    local text=$(printf '%0.sA' {1..10000})
    local result=$(ctx_estimate_tokens "$text")
    # 10000 / 4 = 2500 tokens
    assert_equals "2500" "$result" "Texto muito longo (10000 chars) deve calcular corretamente"
}

test_ctx_estimate_tokens_special_chars() {
    local text="!@#$%^&*()_+-=[]{}|;':\",./<>?"
    local result=$(ctx_estimate_tokens "$text")
    local char_count=${#text}
    local expected=$(( char_count / 4 ))
    if [ "$expected" -eq 0 ]; then
        expected=1
    fi
    assert_equals "$expected" "$result" "Caracteres especiais devem ser contados"
}

test_ctx_estimate_tokens_tabs_and_spaces() {
    local text="    tab	here    spaces"
    local result=$(ctx_estimate_tokens "$text")
    local char_count=${#text}
    local expected=$(( char_count / 4 ))
    if [ "$expected" -eq 0 ]; then
        expected=1
    fi
    assert_equals "$expected" "$result" "Tabs e espacos devem ser contados"
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  CONTEXT MONITOR TEST SUITE - TDD RED PHASE                    ║"
echo "║  AI Dev Superpowers v3.9.0                                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Run all tests
run_test_suite "Context Monitor Tests" \
    test_ctx_estimate_tokens_empty \
    test_ctx_estimate_tokens_short \
    test_ctx_estimate_tokens_medium \
    test_ctx_estimate_tokens_exact_boundary \
    test_ctx_estimate_tokens_unicode \
    test_ctx_estimate_tokens_multiline \
    test_ctx_estimate_tokens_file_not_exists \
    test_ctx_estimate_tokens_file_empty \
    test_ctx_estimate_tokens_file_with_content \
    test_ctx_estimate_tokens_file_large \
    test_ctx_get_usage_percent_zero_max \
    test_ctx_get_usage_percent_zero_used \
    test_ctx_get_usage_percent_50_percent \
    test_ctx_get_usage_percent_100_percent \
    test_ctx_get_usage_percent_over_100 \
    test_ctx_get_usage_percent_25_percent \
    test_ctx_get_usage_percent_75_percent \
    test_ctx_get_usage_percent_1_percent \
    test_ctx_get_usage_percent_99_percent \
    test_ctx_get_remaining_capacity_normal \
    test_ctx_get_remaining_capacity_zero \
    test_ctx_get_remaining_capacity_full \
    test_ctx_get_remaining_capacity_over_limit \
    test_ctx_get_remaining_capacity_exact_boundary \
    test_ctx_should_checkpoint_none \
    test_ctx_should_checkpoint_warning_boundary \
    test_ctx_should_checkpoint_warning_above \
    test_ctx_should_checkpoint_auto_checkpoint_boundary \
    test_ctx_should_checkpoint_auto_checkpoint_above \
    test_ctx_should_checkpoint_force_save_boundary \
    test_ctx_should_checkpoint_force_save_above \
    test_ctx_should_checkpoint_zero \
    test_ctx_should_checkpoint_69_percent \
    test_ctx_should_checkpoint_84_percent \
    test_ctx_should_checkpoint_94_percent \
    test_ctx_get_threshold_warning \
    test_ctx_get_threshold_auto_checkpoint \
    test_ctx_get_threshold_force_save \
    test_ctx_get_threshold_invalid \
    test_ctx_get_threshold_empty \
    test_ctx_format_status_safe \
    test_ctx_format_status_warning \
    test_ctx_format_status_critical \
    test_ctx_format_status_emergency \
    test_ctx_format_status_boundary_safe \
    test_ctx_format_status_boundary_warning \
    test_ctx_format_status_zero \
    test_ctx_format_status_100 \
    test_ctx_update_session_metrics_success \
    test_ctx_update_session_metrics_file_not_exists \
    test_custom_thresholds \
    test_custom_chars_per_token \
    test_ctx_estimate_tokens_very_long \
    test_ctx_estimate_tokens_special_chars \
    test_ctx_estimate_tokens_tabs_and_spaces

# Cleanup
rm -rf "$TEST_DIR"

# Exit with appropriate code
exit $TESTS_FAILED
