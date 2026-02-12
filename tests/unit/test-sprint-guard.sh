#!/bin/bash

# Testes Unitários: Sprint Guard Module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
source "$PROJECT_ROOT/tests/helpers/test-framework.sh"
source "$PROJECT_ROOT/lib/sprint-guard.sh"

test_guard_calculate_score_empty() {
    local score=$(guard_calculate_score "" "")
    assert_equals "0.0" "$score" "Score de campos vazios deve ser 0.0"
}

test_guard_calculate_score_perfect_match() {
    local score=$(guard_calculate_score "implementar login" "implementar login")
    assert_equals "1.0" "$score" "Match perfeito deve retornar 1.0"
}

test_guard_calculate_score_partial_match() {
    # 'implementar' aparece em ambos
    local score=$(guard_calculate_score "implementar login" "implementar logout")
    
    # bc -l retorna 1 para verdadeiro, 0 para falso
    local gt_zero=$(echo "$score > 0" | bc -l)
    local lt_one=$(echo "$score < 1" | bc -l)
    
    [[ "$gt_zero" -eq 1 ]]; assert_true $? "Match parcial deve ser > 0"
    [[ "$lt_one" -eq 1 ]]; assert_true $? "Match parcial deve ser < 1"
}

test_guard_check_under_threshold() {
    export GUARD_THRESHOLD=0.8
    # "fix bug" vs "implement feature" deve ter score baixo
    local output=$(guard_check "fix bug" "implement feature" 2>&1)
    assert_contains "$output" "[SPRINT GUARD]" "Deve emitir aviso quando score está abaixo do threshold"
}

test_guard_get_active_keywords() {
    local keywords=$(guard_get_active_keywords "Implementar autenticação JWT no backend")
    assert_contains "$keywords" "autenticação" "Deve extrair palavras chave relevantes"
    assert_contains "$keywords" "jwt" "Deve extrair palavras chave técnicas"
}

# Executa suite
run_test_suite "Sprint Guard Module" \
    test_guard_calculate_score_empty \
    test_guard_calculate_score_perfect_match \
    test_guard_calculate_score_partial_match \
    test_guard_check_under_threshold \
    test_guard_get_active_keywords \
    test_guard_calculate_score_partial_match \
    test_guard_calculate_score_perfect_match \
    test_guard_calculate_score_empty \
    test_guard_check_under_threshold