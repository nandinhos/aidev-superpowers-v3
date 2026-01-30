#!/bin/bash

# ============================================================================
# Testes Unitários - MCP Module
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_module "mcp"

# ============================================================================
# Testes
# ============================================================================

test_section "MCP - Funções Básicas"

assert_command_succeeds "type generate_mcp_config" "generate_mcp_config existe"
assert_command_succeeds "type setup_mcp_engine" "setup_mcp_engine existe"
assert_command_succeeds "type has_mcp_config" "has_mcp_config existe"
assert_command_succeeds "type mcp_status" "mcp_status existe"
assert_command_succeeds "type validate_mcp_config" "validate_mcp_config existe"

test_section "MCP - Geração de Config"

# Cria diretório de teste
TEST_MCP_DIR="/tmp/aidev-mcp-test"
rm -rf "$TEST_MCP_DIR"
mkdir -p "$TEST_MCP_DIR"

# Gera config para Claude Code
generate_mcp_config "claude-code" "$TEST_MCP_DIR"

# Verifica arquivo criado
assert_file_exists "$TEST_MCP_DIR/.mcp.json" ".mcp.json criado"

# Verifica conteúdo
assert_contains "$(cat "$TEST_MCP_DIR/.mcp.json")" "mcpServers" "Contém mcpServers"
assert_contains "$(cat "$TEST_MCP_DIR/.mcp.json")" "context7" "Contém context7"
assert_contains "$(cat "$TEST_MCP_DIR/.mcp.json")" "serena" "Contém serena"

test_section "MCP - Verificação"

# has_mcp_config deve retornar true
has_mcp_config "$TEST_MCP_DIR" && result="sim" || result="nao"
assert_equals "$result" "sim" "has_mcp_config detecta config"

# Diretório sem config
has_mcp_config "/tmp/nao-existe-aidev" && result="sim" || result="nao"
assert_equals "$result" "nao" "has_mcp_config retorna false para dir sem config"

test_section "MCP - Validação"

# Valida JSON (se jq disponível)
if command -v jq &> /dev/null; then
    assert_command_succeeds "jq . $TEST_MCP_DIR/.mcp.json" "JSON válido com jq"
fi

# Cleanup
rm -rf "$TEST_MCP_DIR"
