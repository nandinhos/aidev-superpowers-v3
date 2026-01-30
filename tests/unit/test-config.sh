#!/bin/bash

# ============================================================================
# Testes Unitários - YAML Parser e Config Merger
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_module "yaml-parser"
load_module "config-merger"

# ============================================================================
# Testes do Parser YAML
# ============================================================================

test_section "YAML Parser - Funções Básicas"

assert_command_succeeds "type parse_yaml" "parse_yaml existe"
assert_command_succeeds "type yaml_get" "yaml_get existe"
assert_command_succeeds "type yaml_get_nested" "yaml_get_nested existe"
assert_command_succeeds "type validate_yaml" "validate_yaml existe"

test_section "YAML Parser - Parse Simples"

# Cria YAML de teste
TEST_YAML="/tmp/aidev-test-config.yaml"
cat > "$TEST_YAML" << 'EOF'
version: 3.0.0
mode: full
debug: true

platform:
  name: claude-code
  enabled: true

skills:
  - brainstorming
  - tdd
EOF

# Parseia
parse_yaml "$TEST_YAML" "TEST_"

# Verifica valores simples
assert_equals "${TEST_version:-}" "3.0.0" "Parse version corretamente"
assert_equals "${TEST_mode:-}" "full" "Parse mode corretamente"
assert_equals "${TEST_debug:-}" "true" "Parse debug corretamente"

# Verifica valores aninhados
assert_equals "${TEST_platform_name:-}" "claude-code" "Parse platform.name"
assert_equals "${TEST_platform_enabled:-}" "true" "Parse platform.enabled"

# Verifica lista
assert_contains "${TEST_skills:-}" "brainstorming" "Parse lista contém brainstorming"
assert_contains "${TEST_skills:-}" "tdd" "Parse lista contém tdd"

test_section "YAML Parser - Validação"

# YAML válido
assert_command_succeeds "validate_yaml $TEST_YAML" "Valida YAML correto"

# ============================================================================
# Testes do Config Merger
# ============================================================================

test_section "Config Merger - Funções Básicas"

assert_command_succeeds "type load_config" "load_config existe"
assert_command_succeeds "type config_get" "config_get existe"
assert_command_succeeds "type config_get_nested" "config_get_nested existe"
assert_command_succeeds "type config_is_true" "config_is_true existe"

test_section "Config Merger - Load Defaults"

# Carrega defaults
load_defaults

# Verifica que carregou
assert_equals "$(config_get 'version' '')" "3.0.0" "Carrega version do defaults"
assert_equals "$(config_get 'mode' '')" "full" "Carrega mode do defaults"

test_section "Config Merger - Hierarquia"

# Cria config de projeto que sobrescreve
PROJECT_CONFIG="/tmp/aidev-test-project/.aidev.yaml"
mkdir -p "/tmp/aidev-test-project"
cat > "$PROJECT_CONFIG" << 'EOF'
mode: minimal
language: en
EOF

# Carrega config completa
load_config "/tmp/aidev-test-project"

# Projeto deve sobrescrever defaults
assert_equals "$(config_get 'mode' '')" "minimal" "Projeto sobrescreve mode"
assert_equals "$(config_get 'language' '')" "en" "Projeto sobrescreve language"

# Mas valores não definidos devem vir do defaults
assert_equals "$(config_get 'version' '')" "3.0.0" "Mantém version do defaults"

test_section "Config Merger - Boolean Helper"

# Define valores para teste
export AIDEV_CFG_debug_enabled="true"
export AIDEV_CFG_force="false"

config_is_true "debug_enabled" && passa="sim" || passa="nao"
assert_equals "$passa" "sim" "config_is_true para true"

config_is_true "force" && passa="sim" || passa="nao"
assert_equals "$passa" "nao" "config_is_true para false"

# Cleanup
rm -f "$TEST_YAML"
rm -rf "/tmp/aidev-test-project"
