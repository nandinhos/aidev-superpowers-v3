#!/bin/bash

# Testes Unitários: Context Compressor Module

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
source "$PROJECT_ROOT/tests/helpers/test-framework.sh"

# Mock ambiente
MOCK_DIR=".aidev/state/sprints/current"
mkdir -p "$MOCK_DIR"
mkdir -p ".aidev/.cache"

# Mock ctxgit_get_recent para evitar erros nos testes
ctxgit_get_recent() {
    echo '[{"action": "test_action", "intent": "test_intent"}]'
}

# Cria unified.json de teste
cat > ".aidev/state/unified.json" <<EOF
{
  "version": "4.0.1",
  "sprint_context": {
    "sprint_name": "Sprint Teste",
    "progress_percentage": 50,
    "current_task_id": "task-1"
  }
}
EOF

# Cria sprint-status.json de teste
cat > "$MOCK_DIR/sprint-status.json" <<EOF
{
  "tasks": [
    { "task_id": "task-1", "name": "Implementar funcionalidade X" }
  ]
}
EOF

source "$PROJECT_ROOT/lib/context-compressor.sh"

test_compressor_generates_file() {
    context_compressor_generate ".aidev/.cache/test_context.md"
    assert_file_exists ".aidev/.cache/test_context.md" "Deve gerar o arquivo de contexto"
}

test_compressor_content() {
    context_compressor_generate ".aidev/.cache/test_context.md"
    local content=$(cat ".aidev/.cache/test_context.md")
    
    assert_contains "$content" "Sprint Teste" "Deve conter nome da sprint"
    assert_contains "$content" "50%" "Deve conter progresso"
    assert_contains "$content" "task-1" "Deve conter ID da task"
    assert_contains "$content" "Implementar funcionalidade X" "Deve conter descrição da task"
    assert_contains "$content" "test_action" "Deve conter atividade mockada"
}

test_compressor_size() {
    context_compressor_generate ".aidev/.cache/test_context.md"
    local size=$(wc -c < ".aidev/.cache/test_context.md")
    # Limite de 500 chars para um contexto ultra-leve
    if [ "$size" -lt 500 ]; then
        echo "✅ PASS: Tamanho do contexto ($size chars) está otimizado"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: Contexto muito grande ($size chars)"
        ((TESTS_FAILED++))
    fi
}

# Executa suite
run_test_suite "Context Compressor" \
    test_compressor_generates_file \
    test_compressor_content \
    test_compressor_size

# Cleanup
rm -f ".aidev/.cache/test_context.md"
