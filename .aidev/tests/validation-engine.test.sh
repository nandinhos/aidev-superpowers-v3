#!/bin/bash
# Testes para validation-engine.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/validators.sh"
source "$SCRIPT_DIR/../lib/validation-engine.sh"

TESTS_PASSED=0
TESTS_FAILED=0

assert_true() {
    local result="$1"
    local message="$2"
    
    if [ "$result" -eq 0 ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_false() {
    local result="$1"
    local message="$2"
    
    if [ "$result" -ne 0 ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "═══════════════════════════════════════════════════"
echo "🧪 Testes da Validation Engine"
echo "═══════════════════════════════════════════════════"
echo ""

# Teste 1: validation_with_retry - sucesso na primeira tentativa
echo "🔄 Testes de validation_with_retry()"
echo "───────────────────────────────────────────────────"

result=$(validation_with_retry "validate_safe_path" "/home/user/test" 2>&1)
assert_true "$?" "Retry com path seguro deve passar na 1ª tentativa"

# Teste 2: validation_with_retry - falha após max retries
result=$(validation_with_retry "validate_safe_path" "/etc/passwd" 2>&1)
assert_false "$?" "Retry com path crítico deve falhar após retries"

# Teste 3: validation_with_fallback - primário sucesso
echo ""
echo "🔄 Testes de validation_with_fallback()"
echo "───────────────────────────────────────────────────"

# Usa dois validadores que passam
result=$(validation_with_fallback "validate_safe_path" "validate_safe_path" "/home/test" "test" 2>&1)
assert_true "$?" "Fallback deve passar quando primário passa"

# Teste 4: validation_enforce em modo warning
result=$(VALIDATION_MODE=warning validation_enforce "validate_safe_path" "/etc/passwd" "Teste de path" 2>&1)
assert_true "$?" "Enforce em modo warning deve retornar 0 (mas avisar)"

echo ""
echo "═══════════════════════════════════════════════════"
echo "📊 RESUMO DOS TESTES"
echo "═══════════════════════════════════════════════════"
echo "✅ Passaram: $TESTS_PASSED"
echo "❌ Falharam: $TESTS_FAILED"
echo "📈 Total: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 TODOS OS TESTES PASSARAM!"
    exit 0
else
    echo "⚠️  ALGUNS TESTES FALHARAM"
    exit 1
fi
