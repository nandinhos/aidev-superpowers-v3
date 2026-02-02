#!/bin/bash

# ============================================================================
# Testes Unitários - Detection Module
# ============================================================================

# Carrega o test runner e módulos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_module "detection"

# ============================================================================
# Setup / Teardown
# ============================================================================

TEST_BASE_DIR="/tmp/aidev-test-projects"

setup() {
    mkdir -p "$TEST_BASE_DIR/laravel-test"
    echo '{"name": "laravel/framework"}' > "$TEST_BASE_DIR/laravel-test/composer.json"
    
    mkdir -p "$TEST_BASE_DIR/node-test"
    echo '{"name": "test-project", "dependencies": {"express": "^4.0.0"}}' > "$TEST_BASE_DIR/node-test/package.json"
    
    mkdir -p "$TEST_BASE_DIR/python-test"
    touch "$TEST_BASE_DIR/python-test/requirements.txt"
}

teardown() {
    rm -rf "$TEST_BASE_DIR"
}

setup

# ============================================================================
# Testes de Detecção de Stack
# ============================================================================

test_section "Detection - Detecção de Stack"

# Testa projetos mock
result=$(detect_stack /tmp/aidev-test-projects/laravel-test)
assert_equals "laravel" "$result" "Detecta Laravel corretamente"

result=$(detect_stack /tmp/aidev-test-projects/node-test)
assert_contains "express node" "$result" "Detecta Node/Express"

result=$(detect_stack /tmp/aidev-test-projects/python-test)
assert_equals "python" "$result" "Detecta Python corretamente"

# Testa diretório inexistente
result=$(detect_stack /tmp/aidev-nonexistent-dir)
assert_equals "generic" "$result" "Retorna generic para diretório inexistente"

# ============================================================================
# Testes de Detecção de Plataforma
# ============================================================================

test_section "Detection - Detecção de Plataforma"

result=$(detect_platform)
assert_not_empty "$result" "Detecta alguma plataforma"

# Se claude está disponível, deve detectar claude-code OU antigravity se estiver neste ambiente
if command -v claude &> /dev/null; then
    # Se antigravity folder existe, ele tem prioridade
    if [ -d "$HOME/.gemini/antigravity" ]; then
        assert_equals "antigravity" "$result" "Detecta Antigravity (prioridade sobre Claude)"
    else
        assert_equals "claude-code" "$result" "Detecta Claude Code"
    fi
fi

# ============================================================================
# Testes de Detecção de Linguagem
# ============================================================================

test_section "Detection - Detecção de Linguagem"

result=$(detect_language /tmp/aidev-test-projects/laravel-test)
assert_equals "php" "$result" "Detecta PHP para projeto Laravel"

result=$(detect_language /tmp/aidev-test-projects/node-test)
assert_equals "javascript" "$result" "Detecta JavaScript para projeto Node"

result=$(detect_language /tmp/aidev-test-projects/python-test)
assert_equals "python" "$result" "Detecta Python para projeto Python"


# ============================================================================
# Testes de Detecção de Nome do Projeto
# ============================================================================

test_section "Detection - Detecção de Nome do Projeto"

result=$(detect_project_name /tmp/aidev-test-projects/laravel-test)
assert_not_empty "$result" "Detecta algum nome de projeto"

result=$(detect_project_name /tmp/aidev-test-projects/node-test)
assert_equals "test-project" "$result" "Detecta nome do projeto Node"

# ============================================================================
# Testes de Contexto Completo
# ============================================================================

test_section "Detection - Contexto Completo"

detect_project_context /tmp/aidev-test-projects/laravel-test
assert_equals "laravel" "$DETECTED_STACK" "DETECTED_STACK populado"
assert_not_empty "$DETECTED_PLATFORM" "DETECTED_PLATFORM populado"
assert_equals "php" "$DETECTED_LANGUAGE" "DETECTED_LANGUAGE populado"

teardown
