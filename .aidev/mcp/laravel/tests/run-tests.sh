#!/usr/bin/env bash
#
# Test Suite para MCP Laravel Docker
# Testes básicos de integração
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_DIR="$(dirname "$SCRIPT_DIR")"
readonly LIB_DIR="$MCP_DIR/lib"

# Contadores
tests_passed=0
tests_failed=0

# ============================================
# Funções de Teste
# ============================================

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

pass() {
    echo -e "${GREEN}✓ PASS${NC} $1"
    ((tests_passed++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC} $1"
    ((tests_failed++))
}

skip() {
    echo -e "${YELLOW}⊘ SKIP${NC} $1"
}

# ============================================
# Testes
# ============================================

test_scripts_exist() {
    log_test "Verificando existência dos scripts..."
    
    local scripts=(
        "docker-discovery.sh"
        "laravel-health-check.sh"
        "mcp-config-generator.sh"
        "docker-events.sh"
        "trigger-orchestrator.sh"
        "mcp-hot-reload.sh"
        "laravel-boost-installer.sh"
        "boost-verification.sh"
        "multi-project-manager.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$LIB_DIR/$script" ]; then
            if [ -x "$LIB_DIR/$script" ]; then
                pass "$script existe e é executável"
            else
                fail "$script existe mas não é executável"
            fi
        else
            fail "$script não encontrado"
        fi
    done
}

test_cli_exists() {
    log_test "Verificando CLI principal..."
    
    if [ -f "$MCP_DIR/bin/aidev-mcp-laravel" ]; then
        if [ -x "$MCP_DIR/bin/aidev-mcp-laravel" ]; then
            pass "CLI principal existe e é executável"
        else
            fail "CLI principal existe mas não é executável"
        fi
    else
        fail "CLI principal não encontrado"
    fi
    
    if [ -f "$MCP_DIR/../../aidev-mcp-laravel" ]; then
        pass "Wrapper na raiz existe"
    else
        fail "Wrapper na raiz não encontrado"
    fi
}

test_dependencies() {
    log_test "Verificando dependências..."
    
    if command -v jq &> /dev/null; then
        pass "jq está instalado"
    else
        fail "jq não está instalado"
    fi
    
    if command -v docker &> /dev/null; then
        pass "docker está instalado"
    else
        skip "docker não está instalado (pode ser normal em CI)"
    fi
}

test_docker_discovery_help() {
    log_test "Testando docker-discovery.sh --help..."
    
    if "$LIB_DIR/docker-discovery.sh" --help &> /dev/null; then
        pass "docker-discovery.sh --help funciona"
    else
        fail "docker-discovery.sh --help falhou"
    fi
}

test_health_check_help() {
    log_test "Testando laravel-health-check.sh --help..."
    
    if "$LIB_DIR/laravel-health-check.sh" --help &> /dev/null; then
        pass "laravel-health-check.sh --help funciona"
    else
        fail "laravel-health-check.sh --help falhou"
    fi
}

test_config_generator_help() {
    log_test "Testando mcp-config-generator.sh --help..."
    
    if "$LIB_DIR/mcp-config-generator.sh" --help &> /dev/null; then
        pass "mcp-config-generator.sh --help funciona"
    else
        fail "mcp-config-generator.sh --help falhou"
    fi
}

test_cli_help() {
    log_test "Testando CLI --help..."
    
    if "$MCP_DIR/bin/aidev-mcp-laravel" --help &> /dev/null; then
        pass "CLI --help funciona"
    else
        fail "CLI --help falhou"
    fi
}

test_state_directories() {
    log_test "Testando criação de diretórios de estado..."
    
    local test_dir="$MCP_DIR/state/test-$$"
    mkdir -p "$test_dir"
    
    if [ -d "$test_dir" ]; then
        pass "Diretório de estado criado"
        rmdir "$test_dir"
    else
        fail "Não foi possível criar diretório de estado"
    fi
}

test_json_parsing() {
    log_test "Testando parsing JSON..."
    
    local test_json='{"test": "value", "number": 123}'
    
    if echo "$test_json" | jq -e '.test' &> /dev/null; then
        pass "Parsing JSON funciona"
    else
        fail "Parsing JSON falhou"
    fi
}

test_docker_mock() {
    log_test "Testando com Docker mock (se disponível)..."
    
    if ! command -v docker &> /dev/null; then
        skip "Docker não disponível"
        return
    fi
    
    if docker info &> /dev/null; then
        pass "Docker daemon está acessível"
        
        # Testar se podemos listar containers
        if docker ps &> /dev/null; then
            pass "docker ps funciona"
        else
            fail "docker ps falhou"
        fi
    else
        skip "Docker daemon não acessível"
    fi
}

# ============================================
# Execução
# ============================================

run_tests() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   MCP Laravel Docker - Test Suite                      ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    test_scripts_exist
    test_cli_exists
    test_dependencies
    test_docker_discovery_help
    test_health_check_help
    test_config_generator_help
    test_cli_help
    test_state_directories
    test_json_parsing
    test_docker_mock
    
    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "Resultados:"
    echo "  ✅ Passaram: $tests_passed"
    echo "  ❌ Falharam: $tests_failed"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    
    if [ "$tests_failed" -eq 0 ]; then
        echo -e "${GREEN}Todos os testes passaram!${NC}"
        exit 0
    else
        echo -e "${RED}Alguns testes falharam${NC}"
        exit 1
    fi
}

# Verificar se estamos no diretório correto
if [ ! -d "$LIB_DIR" ]; then
    echo "Erro: Diretório lib não encontrado"
    echo "Execute este script de: .aidev/mcp/laravel/tests/"
    exit 1
fi

run_tests
