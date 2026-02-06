#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Testes Unitarios do Modulo KB
# ============================================================================
# Testes para lib/kb.sh
#
# Uso: ./tests/unit/test-kb.sh
# ============================================================================

# Diretorio do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Carrega dependencias
source "$PROJECT_ROOT/lib/core.sh"
source "$PROJECT_ROOT/lib/file-ops.sh"

# Contador de testes
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Diretorio temporario para testes
TEST_DIR=""

# ============================================================================
# HELPERS
# ============================================================================

setup() {
    TEST_DIR=$(mktemp -d)
    export CLI_INSTALL_PATH="$TEST_DIR"
    mkdir -p "$TEST_DIR/.aidev/state"
    mkdir -p "$TEST_DIR/.aidev/memory/kb"

    # Carrega modulo KB
    source "$PROJECT_ROOT/lib/kb.sh"
}

teardown() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "  FALHOU: $message"
        echo "    Esperado: $expected"
        echo "    Recebido: $actual"
        return 1
    fi
}

assert_file_exists() {
    local filepath="$1"
    local message="${2:-Arquivo deveria existir}"

    if [ -f "$filepath" ]; then
        return 0
    else
        echo "  FALHOU: $message"
        echo "    Arquivo nao existe: $filepath"
        return 1
    fi
}

assert_file_contains() {
    local filepath="$1"
    local pattern="$2"
    local message="${3:-Arquivo deveria conter pattern}"

    if grep -q "$pattern" "$filepath" 2>/dev/null; then
        return 0
    else
        echo "  FALHOU: $message"
        echo "    Pattern nao encontrado: $pattern"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    local test_function="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "Executando: $test_name"

    setup

    if $test_function; then
        echo "  OK"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    teardown
}

# ============================================================================
# TESTES
# ============================================================================

test_kb_init() {
    kb_init

    # Verifica se diretorio foi criado
    assert_file_exists "$TEST_DIR/.aidev/memory/kb/index.json" "Indice deveria ser criado" || return 1

    # Verifica estrutura do indice
    if command -v jq >/dev/null 2>&1; then
        local total=$(jq -r '.stats.total' "$TEST_DIR/.aidev/memory/kb/index.json")
        assert_equals "0" "$total" "Total deveria ser 0 inicialmente" || return 1
    fi

    return 0
}

test_kb_catalog_resolution() {
    kb_init

    # Cria estado simulado de skill
    cat > "$TEST_DIR/.aidev/state/skills.json" << 'EOF'
{
  "active_skill": "systematic-debugging",
  "skill_states": {
    "systematic-debugging": {
      "status": "completed",
      "checkpoints": [
        {"step": 1, "description": "Reproduzir erro NullPointer", "timestamp": "2026-02-04T10:00:00"},
        {"step": 2, "description": "Isolar componente com problema", "timestamp": "2026-02-04T10:05:00"}
      ],
      "artifacts": [
        {"path": "src/fix.ts", "type": "code"}
      ]
    }
  }
}
EOF

    # Cataloga resolucao
    local result=$(kb_catalog_resolution "systematic-debugging" '{"exception": "NullPointerException em UserService"}')

    # Verifica se arquivo foi criado
    local files=$(find "$TEST_DIR/.aidev/memory/kb" -name "*.md" -type f 2>/dev/null | wc -l)
    [ "$files" -ge 1 ] || { echo "  FALHOU: Nenhum arquivo .md criado"; return 1; }

    # Verifica conteudo do arquivo
    local lesson_file=$(find "$TEST_DIR/.aidev/memory/kb" -name "*.md" -type f | head -1)
    assert_file_contains "$lesson_file" "NullPointerException" "Arquivo deveria conter exception" || return 1
    assert_file_contains "$lesson_file" "learned-lesson" "Arquivo deveria ter tipo learned-lesson" || return 1

    return 0
}

test_kb_format_lesson() {
    local output=$(kb_format_lesson "KB-TEST-001" "TestException" "- Sintoma 1\n- Sintoma 2" "Causa raiz de teste" "codigo de correcao" "systematic-debugging" "[]" "[]")

    # Verifica campos obrigatorios
    echo "$output" | grep -q "id: KB-TEST-001" || { echo "  FALHOU: ID nao encontrado"; return 1; }
    echo "$output" | grep -q "exception:" || { echo "  FALHOU: Exception nao encontrada"; return 1; }
    echo "$output" | grep -q "type: learned-lesson" || { echo "  FALHOU: Type nao encontrado"; return 1; }
    echo "$output" | grep -q "## Sintomas" || { echo "  FALHOU: Secao Sintomas nao encontrada"; return 1; }
    echo "$output" | grep -q "## Causa Raiz" || { echo "  FALHOU: Secao Causa Raiz nao encontrada"; return 1; }
    echo "$output" | grep -q "## Correcao" || { echo "  FALHOU: Secao Correcao nao encontrada"; return 1; }

    return 0
}

test_kb_search_local() {
    kb_init

    # Cria algumas licoes de teste
    cat > "$TEST_DIR/.aidev/memory/kb/2026-02-04-test-null.md" << 'EOF'
---
id: KB-TEST-001
type: learned-lesson
exception: "NullPointerException em UserService"
category: bug
---

# Licao: NullPointerException

Conteudo de teste sobre null pointer.
EOF

    cat > "$TEST_DIR/.aidev/memory/kb/2026-02-04-test-auth.md" << 'EOF'
---
id: KB-TEST-002
type: learned-lesson
exception: "AuthenticationException"
category: bug
---

# Licao: Autenticacao

Conteudo de teste sobre autenticacao.
EOF

    # Busca por "null"
    local result=$(_kb_search_local "null" 5)
    echo "$result" | grep -q "KB-TEST-001" || { echo "  FALHOU: Deveria encontrar licao sobre null"; return 1; }

    # Busca por "autenticacao"
    result=$(_kb_search_local "autenticacao" 5)
    echo "$result" | grep -q "KB-TEST-002" || { echo "  FALHOU: Deveria encontrar licao sobre autenticacao"; return 1; }

    return 0
}

test_kb_update_index() {
    kb_init

    # Cria arquivo de licao fake
    local lesson_file="$TEST_DIR/.aidev/memory/kb/2026-02-04-test.md"
    echo "# Test Lesson" > "$lesson_file"

    # Atualiza indice
    _kb_update_index "$lesson_file" "KB-TEST-001" "TestException" "systematic-debugging"

    # Verifica se indice foi atualizado
    if command -v jq >/dev/null 2>&1; then
        local total=$(jq -r '.stats.total' "$TEST_DIR/.aidev/memory/kb/index.json")
        assert_equals "1" "$total" "Total deveria ser 1 apos adicionar" || return 1

        local by_skill=$(jq -r '.stats.by_skill["systematic-debugging"]' "$TEST_DIR/.aidev/memory/kb/index.json")
        assert_equals "1" "$by_skill" "Contador por skill deveria ser 1" || return 1
    fi

    return 0
}

test_kb_on_failure() {
    kb_init

    # Registra falha
    _kb_on_failure "brainstorming" "Timeout na API"

    # Verifica se foi logado
    assert_file_exists "$TEST_DIR/.aidev/state/kb_failures.log" "Log de falhas deveria existir" || return 1
    assert_file_contains "$TEST_DIR/.aidev/state/kb_failures.log" "brainstorming" "Log deveria conter nome da skill" || return 1
    assert_file_contains "$TEST_DIR/.aidev/state/kb_failures.log" "Timeout" "Log deveria conter motivo" || return 1

    return 0
}

test_kb_consult_before_coding() {
    kb_init

    # Cria licao relevante
    cat > "$TEST_DIR/.aidev/memory/kb/2026-02-04-jwt-auth.md" << 'EOF'
---
id: KB-JWT-001
type: learned-lesson
exception: "JWT Token Expired"
category: bug
---

# Licao: JWT Token Expirado

Problema com renovacao de token JWT.
EOF

    # Consulta sobre JWT
    local result=$(kb_consult_before_coding "implementar autenticacao JWT" 2>&1)

    echo "$result" | grep -q "Knowledge Base" || { echo "  FALHOU: Deveria mostrar titulo da consulta"; return 1; }

    return 0
}

test_kb_stats() {
    kb_init

    # Cria algumas licoes
    _kb_update_index "/fake/path1.md" "KB-001" "Error1" "systematic-debugging"
    _kb_update_index "/fake/path2.md" "KB-002" "Error2" "systematic-debugging"
    _kb_update_index "/fake/path3.md" "KB-003" "Error3" "learned-lesson"

    # Verifica estatisticas
    if command -v jq >/dev/null 2>&1; then
        local total=$(jq -r '.stats.total' "$TEST_DIR/.aidev/memory/kb/index.json")
        assert_equals "3" "$total" "Total deveria ser 3" || return 1

        local debugging=$(jq -r '.stats.by_skill["systematic-debugging"]' "$TEST_DIR/.aidev/memory/kb/index.json")
        assert_equals "2" "$debugging" "Systematic-debugging deveria ter 2" || return 1

        local lesson=$(jq -r '.stats.by_skill["learned-lesson"]' "$TEST_DIR/.aidev/memory/kb/index.json")
        assert_equals "1" "$lesson" "Learned-lesson deveria ter 1" || return 1
    fi

    return 0
}

# ============================================================================
# EXECUCAO
# ============================================================================

echo ""
echo "=========================================="
echo "  Testes Unitarios - lib/kb.sh"
echo "=========================================="
echo ""

run_test "kb_init cria estrutura corretamente" test_kb_init
run_test "kb_catalog_resolution salva licao" test_kb_catalog_resolution
run_test "kb_format_lesson gera formato correto" test_kb_format_lesson
run_test "kb_search_local encontra licoes" test_kb_search_local
run_test "kb_update_index atualiza estatisticas" test_kb_update_index
run_test "kb_on_failure registra falhas" test_kb_on_failure
run_test "kb_consult_before_coding funciona" test_kb_consult_before_coding
run_test "kb_stats mostra estatisticas corretas" test_kb_stats

echo ""
echo "=========================================="
echo "  Resultado: $TESTS_PASSED/$TESTS_RUN passaram"
if [ "$TESTS_FAILED" -gt 0 ]; then
    echo "  FALHAS: $TESTS_FAILED"
    exit 1
else
    echo "  Todos os testes passaram!"
    exit 0
fi
