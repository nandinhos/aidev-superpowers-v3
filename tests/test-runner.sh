#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Test Runner
# ============================================================================
# Framework de testes para validação dos módulos
# 
# Uso: ./tests/test-runner.sh [tests/unit/test-*.sh]
# ============================================================================

# Não usar set -e pois assertions podem retornar 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# Assertions
# ============================================================================

# Assert que dois valores são iguais
# Uso: assert_equals "esperado" "atual" "mensagem"
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    ((TESTS_TOTAL++))
    
    if [ "$expected" = "$actual" ]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    Esperado: ${GREEN}$expected${NC}"
        echo -e "    Obtido:   ${RED}$actual${NC}"
        return 1
    fi
}

# Assert que valor não está vazio
# Uso: assert_not_empty "$valor" "mensagem"
assert_not_empty() {
    local value="$1"
    local message="${2:-}"
    
    ((TESTS_TOTAL++))
    
    if [ -n "$value" ]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message (valor vazio)"
        return 1
    fi
}

# Assert que arquivo existe
# Uso: assert_file_exists "/path/to/file" "mensagem"
assert_file_exists() {
    local file="$1"
    local message="${2:-Arquivo existe: $file}"
    
    ((TESTS_TOTAL++))
    
    if [ -f "$file" ]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message"
        return 1
    fi
}

# Assert que diretório existe
# Uso: assert_dir_exists "/path/to/dir" "mensagem"
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Diretório existe: $dir}"
    
    ((TESTS_TOTAL++))
    
    if [ -d "$dir" ]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message"
        return 1
    fi
}

# Assert que string contém substring
# Uso: assert_contains "haystack" "needle" "mensagem"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    ((TESTS_TOTAL++))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message"
        echo -e "    String: $haystack"
        echo -e "    Não contém: $needle"
        return 1
    fi
}

# Assert que comando tem sucesso
# Uso: assert_command_succeeds "comando" "mensagem"
assert_command_succeeds() {
    local command="$1"
    local message="${2:-Comando bem-sucedido: $command}"
    
    ((TESTS_TOTAL++))
    
    if eval "$command" > /dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message"
        return 1
    fi
}

# Assert que comando falha
# Uso: assert_command_fails "comando" "mensagem"
assert_command_fails() {
    local command="$1"
    local message="${2:-Comando falha corretamente: $command}"
    
    ((TESTS_TOTAL++))
    
    if ! eval "$command" > /dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "  ${RED}✗${NC} $message (comando deveria falhar)"
        return 1
    fi
}

# ============================================================================
# Helpers
# ============================================================================

# Inicia seção de testes
# Uso: test_section "Nome da Seção"
test_section() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
}

# ============================================================================
# Runner
# ============================================================================

# Executa arquivo de testes
run_test_file() {
    local test_file="$1"
    
    if [ -f "$test_file" ]; then
        echo ""
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}  Executando: $(basename "$test_file")${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
        
        # Source o arquivo de teste
        # shellcheck source=/dev/null
        source "$test_file"
    else
        echo -e "${RED}Arquivo de teste não encontrado: $test_file${NC}"
    fi
}

# Exibe relatório final
print_report() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Relatório de Testes${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Total:   $TESTS_TOTAL"
    echo -e "  ${GREEN}Passou:  $TESTS_PASSED${NC}"
    echo -e "  ${RED}Falhou:  $TESTS_FAILED${NC}"
    echo ""
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ Todos os testes passaram!${NC}"
        return 0
    else
        echo -e "${RED}✗ Alguns testes falharam${NC}"
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  AI Dev Superpowers V3 - Test Runner                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    # Se argumentos fornecidos, executa apenas esses testes
    if [ $# -gt 0 ]; then
        for test_file in "$@"; do
            run_test_file "$test_file"
        done
    else
        # Executa todos os testes em tests/unit/
        for test_file in "$SCRIPT_DIR"/unit/test-*.sh; do
            if [ -f "$test_file" ]; then
                run_test_file "$test_file"
            fi
        done
    fi
    
    print_report
}

# Executa se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
