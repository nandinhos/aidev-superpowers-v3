#!/bin/bash
# Testes para error-tracker.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/error-tracker.sh"

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
    
    if [ -n "$value" ] && [ "$value" != "null" ]; then
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
echo "🧪 Testes do Sistema de Backlog"
echo "═══════════════════════════════════════════════════"
echo ""

# Setup
export BACKLOG_FILE="/tmp/test-backlog-$$.json"
rm -f "$BACKLOG_FILE"

# Teste 1: backlog_init
echo "📁 Testes de backlog_init()"
echo "───────────────────────────────────────────────────"

backlog_init
[ -f "$BACKLOG_FILE" ] && assert_true 0 "Arquivo de backlog deve ser criado" || assert_true 1 "Arquivo de backlog deve ser criado"

echo ""

# Teste 2: backlog_add_error
echo "🐛 Testes de backlog_add_error()"
echo "───────────────────────────────────────────────────"

error_id=$(backlog_add_error "Erro de timeout" "API não responde" "high" '["api", "timeout"]')
assert_not_empty "$error_id" "Erro deve ser adicionado e retornar ID"

# Verifica se erro foi adicionado
count=$(jq '.errors | length' "$BACKLOG_FILE")
[ "$count" -eq 1 ] && assert_true 0 "Deve haver 1 erro no backlog" || assert_true 1 "Deve haver 1 erro no backlog"

echo ""

# Teste 3: backlog_resolve_error
echo "✅ Testes de backlog_resolve_error()"
echo "───────────────────────────────────────────────────"

backlog_resolve_error "$error_id" "Aumentado timeout para 60s"
status=$(jq -r ".errors[] | select(.id == \"$error_id\") | .status" "$BACKLOG_FILE")
[ "$status" == "resolved" ] && assert_true 0 "Erro deve estar resolvido" || assert_true 1 "Erro deve estar resolvido"

echo ""

# Teste 4: backlog_list_open_errors
echo "📋 Testes de backlog_list_open_errors()"
echo "───────────────────────────────────────────────────"

# Adiciona mais um erro
error_id2=$(backlog_add_error "Erro de validação" "Campo obrigatório vazio" "critical")

open_errors=$(backlog_list_open_errors)
count=$(echo "$open_errors" | jq 'length')
[ "$count" -eq 1 ] && assert_true 0 "Deve listar apenas erros abertos (1)" || assert_true 1 "Deve listar apenas erros abertos (1)"

echo ""

# Teste 5: backlog_get_critical
echo "🚨 Testes de backlog_get_critical()"
echo "───────────────────────────────────────────────────"

critical=$(backlog_get_critical)
count=$(echo "$critical" | jq 'length')
[ "$count" -eq 1 ] && assert_true 0 "Deve retornar 1 erro crítico" || assert_true 1 "Deve retornar 1 erro crítico"

echo ""

# Teste 6: backlog_add_task
echo "📌 Testes de backlog_add_task()"
echo "───────────────────────────────────────────────────"

task_id=$(backlog_add_task "Implementar cache" "Adicionar Redis" "high" 120)
assert_not_empty "$task_id" "Tarefa deve ser adicionada e retornar ID"

count=$(jq '.tasks | length' "$BACKLOG_FILE")
[ "$count" -eq 1 ] && assert_true 0 "Deve haver 1 tarefa no backlog" || assert_true 1 "Deve haver 1 tarefa no backlog"

echo ""

# Teste 7: backlog_start_task e backlog_complete_task
echo "🔄 Testes de gerenciamento de tarefas"
echo "───────────────────────────────────────────────────"

backlog_start_task "$task_id" "developer"
status=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .status" "$BACKLOG_FILE")
[ "$status" == "in_progress" ] && assert_true 0 "Tarefa deve estar em progresso" || assert_true 1 "Tarefa deve estar em progresso"

backlog_complete_task "$task_id"
status=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .status" "$BACKLOG_FILE")
[ "$status" == "completed" ] && assert_true 0 "Tarefa deve estar completada" || assert_true 1 "Tarefa deve estar completada"

echo ""

# Teste 8: backlog_stats
echo "📊 Testes de backlog_stats()"
echo "───────────────────────────────────────────────────"

stats=$(backlog_stats)
assert_not_empty "$stats" "Estatísticas devem ser geradas"

open_count=$(echo "$stats" | jq -r '.errors.open')
[ "$open_count" -eq 1 ] && assert_true 0 "Stats deve mostrar 1 erro aberto" || assert_true 1 "Stats deve mostrar 1 erro aberto"

echo ""

# Cleanup
rm -f "$BACKLOG_FILE"

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
