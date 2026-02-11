#!/bin/bash
# Testes para validation-pipeline.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/validation-pipeline.sh"

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
echo "🧪 Testes do Pipeline de Validação"
echo "═══════════════════════════════════════════════════"
echo ""

# Teste 1: validate_pre_commit com commit válido
echo "📝 Testes de validate_pre_commit()"
echo "───────────────────────────────────────────────────"

VALIDATION_MODE=warning
result=$(validate_pre_commit "feat(auth): adiciona login" "src/auth.js src/auth.test.js" 2>&1)
assert_true "$?" "Commit válido deve passar"

# Teste 2: validate_pre_write com path seguro
echo ""
echo "📝 Testes de validate_pre_write()"
echo "───────────────────────────────────────────────────"

result=$(validate_pre_write "/home/user/test.txt" "conteudo" 2>&1)
assert_true "$?" "Path seguro deve passar"

# Teste 3: validate_coding_action
echo ""
echo "🔧 Testes de validate_coding_action()"
echo "───────────────────────────────────────────────────"

result=$(validate_coding_action "create" "/tmp/test-validacao.txt" "console.log('test')" "test" 2>&1)
assert_true "$?" "Ação de create válida deve passar"

# Teste 4: orchestrator_safe_write
echo ""
echo "💾 Testes de orchestrator_safe_write()"
echo "───────────────────────────────────────────────────"

TEST_FILE="/tmp/test-safe-write-$$.txt"
result=$(orchestrator_safe_write "$TEST_FILE" "conteudo de teste" "teste" 2>&1)
assert_true "$?" "Escrita segura deve funcionar"

[ -f "$TEST_FILE" ] && assert_true 0 "Arquivo deve existir" || assert_true 1 "Arquivo deve existir"

# Cleanup
rm -f "$TEST_FILE"

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
