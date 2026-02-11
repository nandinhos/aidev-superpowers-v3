#!/bin/bash
# Testes para kb-search.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/kb-search.sh"

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
echo "🧪 Testes do Motor de Busca em KB"
echo "═══════════════════════════════════════════════════"
echo ""

# Setup
TEST_KB_DIR="/tmp/test-kb-$$"
export KB_DIR="$TEST_KB_DIR"
mkdir -p "$TEST_KB_DIR"

# Cria arquivos de teste no KB
cat > "$TEST_KB_DIR/2026-02-11-timeout-error.md" <<'EOF'
---
id: KB-2026-02-11-001
type: learned-lesson
category: bug
exception: "Connection timeout"
tags: [timeout, api, network]
resolved_at: 2026-02-11T10:00:00Z
---

# Timeout em API Externa

## Contexto
Erro de timeout ao conectar com API de pagamento

## Sintomas
- Connection timeout after 30 seconds
- API não responde

## Causa Raiz
API externa instável

## Solução
Adicionar retry com backoff exponencial
EOF

cat > "$TEST_KB_DIR/2026-02-10-null-pointer.md" <<'EOF'
---
id: KB-2026-02-10-002
type: learned-lesson
category: bug
exception: "NullPointerException"
tags: [java, null, error]
resolved_at: 2026-02-10T15:00:00Z
---

# NullPointerException em UserService

## Contexto
Erro ao processar usuário sem email

## Sintomas
- NullPointerException na linha 42
- Usuário retornado null

## Solução
Adicionar verificação de null
EOF

cat > "$TEST_KB_DIR/2026-02-09-config-error.md" <<'EOF'
---
id: KB-2026-02-09-003
type: learned-lesson
category: config
exception: "Invalid configuration"
tags: [config, yaml, error]
resolved_at: 2026-02-09T09:00:00Z
---

# Configuração Inválida

## Contexto
Erro ao carregar configuração YAML

## Solução
Validar sintaxe YAML antes de deploy
EOF

# Teste 1: Busca local por keyword
echo "🔍 Testes de kb_search_local()"
echo "───────────────────────────────────────────────────"

results=$(kb_search_local "timeout api" 5)
assert_not_empty "$results" "Busca deve retornar resultados"

count=$(echo "$results" | jq 'length')
[ "$count" -ge 1 ] && assert_true 0 "Deve encontrar pelo menos 1 resultado" || assert_true 1 "Deve encontrar pelo menos 1 resultado"

# Verifica se o resultado tem os campos esperados
has_score=$(echo "$results" | jq '.[0].score // 0')
[ "$has_score" -gt 0 ] && assert_true 0 "Resultado deve ter score maior que 0" || assert_true 1 "Resultado deve ter score maior que 0"

echo ""

# Teste 2: Busca sem resultados
echo "🔍 Testes de busca vazia"
echo "───────────────────────────────────────────────────"

results=$(kb_search_local "xyz123naoexiste" 5)
count=$(echo "$results" | jq 'length')
[ "$count" -eq 0 ] && assert_true 0 "Busca por termo inexistente deve retornar vazio" || assert_true 1 "Busca por termo inexistente deve retornar vazio"

echo ""

# Teste 3: Busca por categoria
echo "📂 Testes de kb_search_by_category()"
echo "───────────────────────────────────────────────────"

results=$(kb_search_by_category "bug" 10)
count=$(echo "$results" | jq 'length')
[ "$count" -ge 2 ] && assert_true 0 "Deve encontrar bugs (2+ resultados)" || assert_true 1 "Deve encontrar bugs (2+ resultados)"

echo ""

# Teste 4: kb_search principal
echo "🌐 Testes de kb_search()"
echo "───────────────────────────────────────────────────"

results=$(kb_search "null pointer" 5 false)
assert_not_empty "$results" "Busca principal deve funcionar"

count=$(echo "$results" | jq 'length')
[ "$count" -ge 1 ] && assert_true 0 "Deve retornar resultados" || assert_true 1 "Deve retornar resultados"

echo ""

# Teste 5: kb_check_lessons_before_action
echo "⚠️  Testes de kb_check_lessons_before_action()"
echo "───────────────────────────────────────────────────"

# Deve encontrar lição relevante
if kb_check_lessons_before_action "timeout api connection" 30 >/dev/null 2>&1; then
    assert_true 0 "Deve detectar lição relevante para timeout"
else
    assert_true 1 "Deve detectar lição relevante para timeout"
fi

# Não deve encontrar para termo irrelevante
if kb_check_lessons_before_action "xyz123irrelevante" 30 >/dev/null 2>&1; then
    assert_true 1 "Não deve detectar lição para termo irrelevante"
else
    assert_true 0 "Não deve detectar lição para termo irrelevante"
fi

echo ""

# Teste 6: kb_build_index
echo "📚 Testes de kb_build_index()"
echo "───────────────────────────────────────────────────"

export KB_INDEX="/tmp/test-kb-index-$$.json"
kb_build_index >/dev/null 2>&1

[ -f "$KB_INDEX" ] && assert_true 0 "Índice deve ser criado" || assert_true 1 "Índice deve ser criado"

index_count=$(jq 'length' "$KB_INDEX")
[ "$index_count" -eq 3 ] && assert_true 0 "Índice deve ter 3 entradas" || assert_true 1 "Índice deve ter 3 entradas"

echo ""

# Teste 7: kb_stats
echo "📊 Testes de kb_stats()"
echo "───────────────────────────────────────────────────"

output=$(kb_stats 2>&1)
assert_not_empty "$output" "kb_stats deve produzir output"

# Cleanup
rm -rf "$TEST_KB_DIR" "$KB_INDEX"

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
