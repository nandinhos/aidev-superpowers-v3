#!/bin/bash

# ============================================================================
# Testes Unitários - Core Module
# ============================================================================

# Carrega o test runner e módulos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_essential_modules

# ============================================================================
# Testes
# ============================================================================

test_section "Core - Variáveis"

assert_not_empty "$AIDEV_VERSION" "AIDEV_VERSION está definida"
assert_equals "3.8.1" "$AIDEV_VERSION" "AIDEV_VERSION = 3.8.1"
assert_not_empty "$RED" "Cor RED definida"
assert_not_empty "$GREEN" "Cor GREEN definida"
assert_not_empty "$NC" "Cor NC (reset) definida"

test_section "Core - Funções de Resolução"

assert_command_succeeds "type resolve_path" "resolve_path existe"
resolved=$(resolve_path "\$HOME/test")
assert_equals "$HOME/test" "$resolved" "Resolve \$HOME literal"
resolved=$(resolve_path "~/test")
assert_equals "$HOME/test" "$resolved" "Resolve ~ (til)"
resolved=$(resolve_path "/tmp/test")
assert_equals "/tmp/test" "$resolved" "Mantém caminho absoluto fixo"

test_section "Core - Funções de Output"

# Testa que funções existem
assert_command_succeeds "type print_header" "print_header existe"
assert_command_succeeds "type print_step" "print_step existe"
assert_command_succeeds "type print_success" "print_success existe"
assert_command_succeeds "type print_info" "print_info existe"
assert_command_succeeds "type print_warning" "print_warning existe"
assert_command_succeeds "type print_error" "print_error existe"
assert_command_succeeds "type print_summary" "print_summary existe"

# Testa output
output=$(print_success "teste" 2>&1)
assert_contains "$output" "✓" "print_success contém checkmark"

output=$(print_error "teste" 2>&1)
assert_contains "$output" "✗" "print_error contém X"

test_section "Core - Contadores"

reset_counters
assert_equals "0" "$AIDEV_FILES_CREATED" "Contador de arquivos zerado"
assert_equals "0" "$AIDEV_DIRS_CREATED" "Contador de diretórios zerado"

increment_files
increment_files
assert_equals "2" "$AIDEV_FILES_CREATED" "Contador de arquivos incrementado"

increment_dirs
assert_equals "1" "$AIDEV_DIRS_CREATED" "Contador de diretórios incrementado"
