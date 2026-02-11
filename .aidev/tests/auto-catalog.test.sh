#!/bin/bash
# Testes para auto-catalog.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/auto-catalog.sh"

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

assert_not_empty() {
    local value="$1"
    local message="$2"
    
    if [ -n "$value" ] && [ "$value" != "null" ] && [ "$value" != "[]" ]; then
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
echo "🧪 Testes do Sistema de Auto-Catalogação"
echo "═══════════════════════════════════════════════════"
echo ""

# Setup
TEST_STATE_FILE="/tmp/test-error-detector-$$.json"
export ERROR_DETECTOR_STATE="$TEST_STATE_FILE"
export KB_DIR="/tmp/test-kb-$$"
mkdir -p "$KB_DIR"

# Limpar estado anterior
rm -f "$TEST_STATE_FILE"

# Teste 1: error_detector_init
echo "🔍 Testes de error_detector_init()"
echo "───────────────────────────────────────────────────"

error_detector_init "task-test-001" "NullPointerException" "Teste de erro"
assert_true "$?" "Deve criar entry no detector"

# Verifica se arquivo foi criado
[ -f "$TEST_STATE_FILE" ] && assert_true 0 "Arquivo de estado deve existir" || assert_true 1 "Arquivo de estado deve existir"

# Verifica se entry foi adicionada
count=$(jq 'length' "$TEST_STATE_FILE")
[ "$count" -eq 1 ] && assert_true 0 "Deve ter 1 entry registrada" || assert_true 1 "Deve ter 1 entry registrada"

echo ""

# Teste 2: Verificar resolução sem test command
echo "✅ Testes de error_detector_check_resolution()"
echo "───────────────────────────────────────────────────"

# Adiciona entry resolvida para teste
error_detector_init "task-test-002" "ConnectionError" "Erro de conexão"

# Sem comando de teste e sem mudanças no git, deve retornar STILL_FAILING
result=$(error_detector_check_resolution "task-test-002" 2>/dev/null)
[ "$result" == "STILL_FAILING" ] && assert_true 0 "Sem mudanças deve retornar STILL_FAILING" || assert_true 1 "Sem mudanças deve retornar STILL_FAILING"

echo ""

# Teste 3: error_detector_mark_resolved e get_uncataloged
echo "📦 Testes de marcação como resolvido"
echo "───────────────────────────────────────────────────"

# Marca como resolvido
error_detector_mark_resolved "task-test-001"

# Verifica se foi marcado
status=$(jq -r '.[0].status' "$TEST_STATE_FILE")
[ "$status" == "resolved" ] && assert_true 0 "Status deve ser 'resolved'" || assert_true 1 "Status deve ser 'resolved'"

# Verifica lista de não-catalogados
uncataloged=$(error_detector_get_uncataloged)
count=$(echo "$uncataloged" | jq 'length')
[ "$count" -eq 1 ] && assert_true 0 "Deve haver 1 erro resolvido não-catalogado" || assert_true 1 "Deve haver 1 erro resolvido não-catalogado"

echo ""

# Teste 4: Criação de lição
echo "📝 Testes de _create_lesson_from_error()"
echo "───────────────────────────────────────────────────"

lesson_file=$(_create_lesson_from_error "task-test-003" "SyntaxError" "Erro de sintaxe na linha 42")
assert_not_empty "$lesson_file" "Lição deve ser criada"

[ -f "$lesson_file" ] && assert_true 0 "Arquivo de lição deve existir" || assert_true 1 "Arquivo de lição deve existir"

# Verifica se contém campos necessários
grep -q "type: learned-lesson" "$lesson_file" && assert_true 0 "Lição deve ter type correto" || assert_true 1 "Lição deve ter type correto"
grep -q "SyntaxError" "$lesson_file" && assert_true 0 "Lição deve conter padrão de erro" || assert_true 1 "Lição deve conter padrão de erro"

echo ""

# Teste 5: error_detector_mark_cataloged
echo "🏷️  Testes de marcação como catalogado"
echo "───────────────────────────────────────────────────"

error_detector_mark_cataloged "task-test-001"
cataloged=$(jq -r '.[0].cataloged' "$TEST_STATE_FILE")
[ "$cataloged" == "true" ] && assert_true 0 "Deve estar marcado como catalogado" || assert_true 1 "Deve estar marcado como catalogado"

# Agora deve retornar vazio (todos catalogados)
uncataloged=$(error_detector_get_uncataloged)
count=$(echo "$uncataloged" | jq 'length')
[ "$count" -eq 0 ] && assert_true 0 "Não deve haver erros não-catalogados" || assert_true 1 "Não deve haver erros não-catalogados"

echo ""

# Teste 6: auto_catalog_pre_coding
echo "🔎 Testes de auto_catalog_pre_coding()"
echo "───────────────────────────────────────────────────"

# Descrição com palavra "erro" deve registrar
auto_catalog_pre_coding "Corrigir erro de conexão com banco" 2>/dev/null
count=$(jq 'length' "$TEST_STATE_FILE")
[ "$count" -ge 2 ] && assert_true 0 "Deve registrar erro na descrição" || assert_true 1 "Deve registrar erro na descrição"

echo ""

# Cleanup
rm -rf "$TEST_STATE_FILE" "$KB_DIR"

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
