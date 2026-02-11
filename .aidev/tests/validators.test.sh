#!/bin/bash
# Testes unitários para validators.sh
# TDD: RED → GREEN → REFACTOR

# set -e removido - testes precisam capturar códigos de erro

# Importa funções a serem testadas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/validators.sh"

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0

# Função de assert
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" == "$actual" ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message"
        echo "   Esperado: $expected"
        echo "   Obtido: $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_true() {
    local result="$1"
    local message="$2"
    
    if [ "$result" -eq 0 ]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL: $message (esperado true, obtido false)"
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
        echo "❌ FAIL: $message (esperado false, obtido true)"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "═══════════════════════════════════════════════════"
echo "🧪 Testes de Validação - validators.sh"
echo "═══════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════
# TESTE 1: validate_safe_path
# ═══════════════════════════════════════════════════
echo "📁 Testes de validate_safe_path()"
echo "───────────────────────────────────────────────────"

# Teste 1.1: Path seguro deve retornar 0 (sucesso)
result=$(validate_safe_path "/home/user/projects/test" 2>/dev/null)
assert_true "$?" "Path seguro (/home/user/projects/test) deve ser válido"

# Teste 1.2: Path crítico /etc deve retornar 1 (erro)
result=$(validate_safe_path "/etc/passwd" 2>/dev/null)
assert_false "$?" "Path crítico (/etc/passwd) deve ser bloqueado"

# Teste 1.3: Path crítico /usr deve ser bloqueado
result=$(validate_safe_path "/usr/bin" 2>/dev/null)
assert_false "$?" "Path crítico (/usr/bin) deve ser bloqueado"

# Teste 1.4: Path raiz deve ser bloqueado
result=$(validate_safe_path "/" 2>/dev/null)
assert_false "$?" "Path raiz (/) deve ser bloqueado"

# Teste 1.5: Path com /etc no meio deve ser bloqueado
result=$(validate_safe_path "/home/user/etc/config" 2>/dev/null)
assert_true "$?" "Path com 'etc' no meio (/home/user/etc) deve ser permitido"

echo ""

# ═══════════════════════════════════════════════════
# TESTE 2: validate_commit_format
# ═══════════════════════════════════════════════════
echo "📝 Testes de validate_commit_format()"
echo "───────────────────────────────────────────────────"

# Teste 2.1: Formato válido feat
result=$(validate_commit_format "feat(auth): adiciona login" 2>/dev/null)
assert_true "$?" "Commit válido feat(auth): deve ser aceito"

# Teste 2.2: Formato válido fix
result=$(validate_commit_format "fix(api): corrige validacao" 2>/dev/null)
assert_true "$?" "Commit válido fix(api): deve ser aceito"

# Teste 2.3: Formato válido refactor
result=$(validate_commit_format "refactor(utils): extrai funcao" 2>/dev/null)
assert_true "$?" "Commit válido refactor(utils): deve ser aceito"

# Teste 2.4: Formato inválido (sem tipo)
result=$(validate_commit_format "adiciona login" 2>/dev/null)
assert_false "$?" "Commit sem tipo deve ser rejeitado"

# Teste 2.5: Formato inválido (sem escopo)
result=$(validate_commit_format "feat: adiciona login" 2>/dev/null)
assert_false "$?" "Commit sem escopo deve ser rejeitado"

# Teste 2.6: Formato válido mas descrição em inglês
# Nota: validate_commit_format valida apenas o formato, não o idioma
# A validação de idioma deve ser feita separadamente com validate_portuguese_language
result=$(validate_commit_format "feat(auth): add login" 2>/dev/null)
assert_true "$?" "Commit em formato válido deve ser aceito (idioma é validado separadamente)"

# Teste 2.7: Tipo inválido
result=$(validate_commit_format "invalid(auth): teste" 2>/dev/null)
assert_false "$?" "Commit com tipo inválido deve ser rejeitado"

echo ""

# ═══════════════════════════════════════════════════
# TESTE 3: validate_no_emoji
# ═══════════════════════════════════════════════════
echo "😀 Testes de validate_no_emoji()"
echo "───────────────────────────────────────────────────"

# Teste 3.1: Texto sem emoji deve passar
result=$(validate_no_emoji "Texto normal sem emoji" 2>/dev/null)
assert_true "$?" "Texto sem emoji deve ser válido"

# Teste 3.2: Texto com emoji deve falhar
result=$(validate_no_emoji "Texto com emoji 😀" 2>/dev/null)
assert_false "$?" "Texto com emoji deve ser rejeitado"

# Teste 3.3: Commit com emoji sparkle
result=$(validate_no_emoji "feat: ✨ nova feature" 2>/dev/null)
assert_false "$?" "Texto com ✨ deve ser rejeitado"

# Teste 3.4: Vários emojis
result=$(validate_no_emoji "🚀🔥💯 Teste" 2>/dev/null)
assert_false "$?" "Texto com múltiplos emojis deve ser rejeitado"

echo ""

# ═══════════════════════════════════════════════════
# TESTE 4: validate_portuguese_language
# ═══════════════════════════════════════════════════
echo "🌎 Testes de validate_portuguese_language()"
echo "───────────────────────────────────────────────────"

# Teste 4.1: Texto em português deve passar
result=$(validate_portuguese_language "adiciona funcionalidade" 2>/dev/null)
assert_true "$?" "Texto em português deve ser válido"

# Teste 4.2: Texto em inglês (add) deve falhar
result=$(validate_portuguese_language "add new feature" 2>/dev/null)
assert_false "$?" "Texto em inglês (add) deve ser rejeitado"

# Teste 4.3: Texto em inglês (fix) deve falhar
result=$(validate_portuguese_language "fix bug" 2>/dev/null)
assert_false "$?" "Texto em inglês (fix) deve ser rejeitado"

# Teste 4.4: Texto em português com acentos
result=$(validate_portuguese_language "correção de bug" 2>/dev/null)
assert_true "$?" "Texto em português com acentos deve ser válido"

echo ""

# ═══════════════════════════════════════════════════
# TESTE 5: validate_no_forbidden_patterns
# ═══════════════════════════════════════════════════
echo "🚫 Testes de validate_no_forbidden_patterns()"
echo "───────────────────────────────────────────────────"

# Teste 5.1: Código seguro deve passar
result=$(validate_no_forbidden_patterns "console.log('teste')" 2>/dev/null)
assert_true "$?" "Código sem padrões proibidos deve ser válido"

# Teste 5.2: eval() deve ser bloqueado
result=$(validate_no_forbidden_patterns "eval(codigo)" 2>/dev/null)
assert_false "$?" "Uso de eval() deve ser bloqueado"

# Teste 5.3: innerHTML deve ser bloqueado
result=$(validate_no_forbidden_patterns "element.innerHTML = '<script>'" 2>/dev/null)
assert_false "$?" "Uso de innerHTML deve ser bloqueado"

# Teste 5.4: rm -rf / deve ser bloqueado
result=$(validate_no_forbidden_patterns "rm -rf /" 2>/dev/null)
assert_false "$?" "Comando rm -rf / deve ser bloqueado"

echo ""

# ═══════════════════════════════════════════════════
# TESTE 6: validate_test_exists
# ═══════════════════════════════════════════════════
echo "🧪 Testes de validate_test_exists()"
echo "───────────────────────────────────────────────────"

# Criar estrutura de teste temporária
TEST_DIR="/tmp/test_validation_$$"
mkdir -p "$TEST_DIR/src"

# Teste 6.1: Arquivo com teste correspondente
echo "test" > "$TEST_DIR/src/auth.js"
echo "test" > "$TEST_DIR/src/auth.test.js"
(cd "$TEST_DIR" && validate_test_exists "src/auth.js" 2>/dev/null)
assert_true "$?" "Arquivo com teste .test.js deve passar"

# Teste 6.2: Arquivo sem teste deve falhar
echo "test" > "$TEST_DIR/src/utils.js"
rm -f "$TEST_DIR/src/utils.test.js"
(cd "$TEST_DIR" && validate_test_exists "src/utils.js" 2>/dev/null)
assert_false "$?" "Arquivo sem teste deve falhar"

# Limpar
rm -rf "$TEST_DIR"

echo ""

# ═══════════════════════════════════════════════════
# TESTE 7: validate_no_co_authored
# ═══════════════════════════════════════════════════
echo "👥 Testes de validate_no_co_authored()"
echo "───────────────────────────────────────────────────"

# Teste 7.1: Commit normal sem co-authored deve passar
result=$(validate_no_co_authored "feat(auth): adiciona login" 2>/dev/null)
assert_true "$?" "Commit sem Co-Authored-By deve ser válido"

# Teste 7.2: Commit com Co-Authored-By deve falhar
result=$(validate_no_co_authored "feat(auth): adiciona login

Co-Authored-By: Claude <claude@anthropic.com>" 2>/dev/null)
assert_false "$?" "Commit com Co-Authored-By deve ser rejeitado"

# Teste 7.3: Variação de case - Co-authored-by
result=$(validate_no_co_authored "fix: corrige bug

co-authored-by: AI <ai@example.com>" 2>/dev/null)
assert_false "$?" "Co-authored-by (lowercase) deve ser rejeitado"

# Teste 7.4: Validação no formato do commit
result=$(validate_commit_format "feat(auth): teste

Co-Authored-By: Test <test@test.com>" 2>/dev/null)
assert_false "$?" "validate_commit_format deve rejeitar Co-Authored-By"

echo ""

# ═══════════════════════════════════════════════════
# RESUMO
# ════════════════════════════════════════════════════
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
