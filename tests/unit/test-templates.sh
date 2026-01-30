#!/bin/bash

# ============================================================================
# Testes Unitários - Templates Module
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_module "templates"

# ============================================================================
# Testes
# ============================================================================

test_section "Templates - Sistema de Processamento"

# Testa que o módulo carregou
assert_command_succeeds "type process_template" "process_template existe"
assert_command_succeeds "type list_templates" "list_templates existe"
assert_command_succeeds "type validate_template" "validate_template existe"

test_section "Templates - Variáveis Simples"

# Cria template de teste temporário
TEST_TEMPLATE="/tmp/aidev-test-template.tmpl"
echo 'Hello {{NAME}}! Welcome to {{PROJECT}}.' > "$TEST_TEMPLATE"

export NAME="World"
export PROJECT="AIDev"

result=$(process_template "$TEST_TEMPLATE" "")
assert_contains "$result" "Hello World" "Substitui variável NAME"
assert_contains "$result" "Welcome to AIDev" "Substitui variável PROJECT"

test_section "Templates - Variáveis com Default"

echo 'Stack: {{STACK:generic}}' > "$TEST_TEMPLATE"
unset STACK
result=$(process_template "$TEST_TEMPLATE" "")
assert_contains "$result" "Stack: generic" "Usa valor default quando variável não definida"

export STACK="laravel"
result=$(process_template "$TEST_TEMPLATE" "")
assert_contains "$result" "Stack: laravel" "Substitui quando variável definida"

test_section "Templates - Listagem"

# Testa listagem de categorias
categories=$(list_template_categories)
assert_contains "$categories" "agents" "Lista categoria agents"
assert_contains "$categories" "skills" "Lista categoria skills"
assert_contains "$categories" "rules" "Lista categoria rules"

# Testa listagem de templates
templates=$(list_templates "agents")
assert_not_empty "$templates" "Lista templates de agents"

test_section "Templates - Validação"

# Template válido
echo '{{VAR}} text {{#if COND}}inner{{/if}}' > "$TEST_TEMPLATE"
assert_command_succeeds "validate_template $TEST_TEMPLATE" "Valida template correto"

# Cleanup
rm -f "$TEST_TEMPLATE"
