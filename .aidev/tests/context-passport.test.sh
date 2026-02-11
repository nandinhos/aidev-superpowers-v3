#!/bin/bash
# Testes para context-passport.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/context-passport.sh"

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

assert_not_empty() {
    local value="$1"
    local message="$2"
    
    if [ -n "$value" ] && [ "$value" != "{}" ]; then
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
echo "🧪 Testes do Context Passport"
echo "═══════════════════════════════════════════════════"
echo ""

# Teste 1: Criar passport
echo "📋 Testes de passport_create()"
echo "───────────────────────────────────────────────────"

pp=$(passport_create "task-test-001" "backend")
assert_not_empty "$pp" "Passport deve ser criado com sucesso"

# Verifica campos obrigatórios
pp_id=$(echo "$pp" | jq -r '.passport_id')
assert_not_empty "$pp_id" "Passport deve ter ID gerado"

pp_task=$(echo "$pp" | jq -r '.task_id')
[ "$pp_task" == "task-test-001" ] && assert_true 0 "Task ID correto" || assert_true 1 "Task ID correto"

pp_role=$(echo "$pp" | jq -r '.agent_role')
[ "$pp_role" == "backend" ] && assert_true 0 "Agent role correto" || assert_true 1 "Agent role correto"

echo ""

# Teste 2: Salvar e carregar passport
echo "💾 Testes de passport_save() e passport_load()"
echo "───────────────────────────────────────────────────"

pp_file=$(passport_save "$pp")
assert_not_empty "$pp_file" "Passport deve ser salvo"
[ -f "$pp_file" ] && assert_true 0 "Arquivo deve existir" || assert_true 1 "Arquivo deve existir"

pp_loaded=$(passport_load "task-test-001")
assert_not_empty "$pp_loaded" "Passport deve ser carregado"

echo ""

# Teste 3: Adicionar arquivo de contexto
echo "📁 Testes de passport_add_context_file()"
echo "───────────────────────────────────────────────────"

# Cria arquivo de teste
echo "test content" > /tmp/test-context.txt

passport_add_context_file "$pp_file" "/tmp/test-context.txt" 0.8 "Arquivo de teste"
files_count=$(jq '.context_files | length' "$pp_file")
[ "$files_count" -eq 1 ] && assert_true 0 "Arquivo adicionado ao contexto" || assert_true 1 "Arquivo adicionado ao contexto"

rm /tmp/test-context.txt

echo ""

# Teste 4: Adicionar referência KB
echo "📚 Testes de passport_add_kb_reference()"
echo "───────────────────────────────────────────────────"

passport_add_kb_reference "$pp_file" "KB-2026-02-11-001" "2026-02-11-test.md" 85
kb_count=$(jq '.kb_references | length' "$pp_file")
[ "$kb_count" -eq 1 ] && assert_true 0 "Referência KB adicionada" || assert_true 1 "Referência KB adicionada"

echo ""

# Teste 5: Compactar passport
echo "🗜️  Testes de passport_compact()"
echo "───────────────────────────────────────────────────"

pp_compact=$(passport_compact "$pp_file")
assert_not_empty "$pp_compact" "Passport compactado deve existir"

# Verifica se campos foram reduzidos
compact_fields=$(echo "$pp_compact" | jq 'keys | length')
full_fields=$(jq 'keys | length' "$pp_file")
[ "$compact_fields" -lt "$full_fields" ] && assert_true 0 "Versão compacta tem menos campos" || assert_true 1 "Versão compacta tem menos campos"

echo ""

# Teste 6: Estimativa de tokens
echo "🎫 Testes de passport_estimate_tokens()"
echo "───────────────────────────────────────────────────"

tokens=$(passport_estimate_tokens "$pp_file")
[ "$tokens" -gt 0 ] && assert_true 0 "Estimativa de tokens deve ser positiva" || assert_true 1 "Estimativa de tokens deve ser positiva"

echo ""

# Limpar testes
rm -f "$pp_file"

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
