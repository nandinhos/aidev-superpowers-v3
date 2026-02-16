#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Release Tests
# ============================================================================
# Testes para o modulo de bump de versao
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source modules under test
if [ -f "$ROOT_DIR/lib/core.sh" ]; then
    source "$ROOT_DIR/lib/core.sh"
fi
if [ -f "$ROOT_DIR/lib/release.sh" ]; then
    source "$ROOT_DIR/lib/release.sh"
fi

# ============================================================================
# Tests: Funcoes existem
# ============================================================================

test_section "release - Funcoes existem"

if type release_calc_next_version &>/dev/null; then
    assert_equals "0" "0" "release_calc_next_version funcao existe"
else
    assert_equals "0" "1" "release_calc_next_version funcao existe"
fi

if type release_get_current_version &>/dev/null; then
    assert_equals "0" "0" "release_get_current_version funcao existe"
else
    assert_equals "0" "1" "release_get_current_version funcao existe"
fi

# ============================================================================
# Tests: release_calc_next_version
# ============================================================================

test_section "release_calc_next_version - Calculo de versao"

if type release_calc_next_version &>/dev/null; then
    # Test: patch bump
    result=$(release_calc_next_version "4.3.0" "patch")
    assert_equals "4.3.1" "$result" "4.3.0 + patch = 4.3.1"

    # Test: minor bump
    result=$(release_calc_next_version "4.3.0" "minor")
    assert_equals "4.4.0" "$result" "4.3.0 + minor = 4.4.0"

    # Test: major bump
    result=$(release_calc_next_version "4.3.0" "major")
    assert_equals "5.0.0" "$result" "4.3.0 + major = 5.0.0"

    # Test: current (sem incremento)
    result=$(release_calc_next_version "4.3.0" "current")
    assert_equals "4.3.0" "$result" "4.3.0 + current = 4.3.0"

    # Test: patch com numeros maiores
    result=$(release_calc_next_version "10.20.99" "patch")
    assert_equals "10.20.100" "$result" "10.20.99 + patch = 10.20.100"

    # Test: minor reseta patch
    result=$(release_calc_next_version "4.3.5" "minor")
    assert_equals "4.4.0" "$result" "4.3.5 + minor = 4.4.0 (reseta patch)"

    # Test: major reseta minor e patch
    result=$(release_calc_next_version "4.3.5" "major")
    assert_equals "5.0.0" "$result" "4.3.5 + major = 5.0.0 (reseta minor e patch)"
else
    assert_equals "0" "1" "release_calc_next_version nao disponivel"
fi

# ============================================================================
# Tests: release_get_current_version
# ============================================================================

test_section "release_get_current_version - Leitura de versao"

if type release_get_current_version &>/dev/null; then
    # Test: le versao do arquivo VERSION
    TEST_TEMP=$(mktemp -d)
    echo "4.5.0" > "$TEST_TEMP/VERSION"
    result=$(release_get_current_version "$TEST_TEMP")
    assert_equals "4.5.0" "$result" "le versao do arquivo VERSION"
    rm -rf "$TEST_TEMP"

    # Test: falha quando nao existe VERSION nem core.sh
    TEST_TEMP=$(mktemp -d)
    release_get_current_version "$TEST_TEMP" 2>/dev/null
    assert_equals "1" "$?" "falha quando nao existe arquivo de versao"
    rm -rf "$TEST_TEMP"
else
    assert_equals "0" "1" "release_get_current_version nao disponivel"
fi
