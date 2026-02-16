#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Version Check Tests
# ============================================================================
# Testes para o modulo de comparacao de versao semver
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source modules under test
if [ -f "$ROOT_DIR/lib/core.sh" ]; then
    source "$ROOT_DIR/lib/core.sh"
fi
if [ -f "$ROOT_DIR/lib/version-check.sh" ]; then
    source "$ROOT_DIR/lib/version-check.sh"
fi

# ============================================================================
# Tests: Funcoes existem
# ============================================================================

test_section "version-check - Funcoes existem"

if type version_check_compare &>/dev/null; then
    assert_equals "0" "0" "version_check_compare funcao existe"
else
    assert_equals "0" "1" "version_check_compare funcao existe"
fi

if type version_check_get_remote &>/dev/null; then
    assert_equals "0" "0" "version_check_get_remote funcao existe"
else
    assert_equals "0" "1" "version_check_get_remote funcao existe"
fi

if type version_check_is_outdated &>/dev/null; then
    assert_equals "0" "0" "version_check_is_outdated funcao existe"
else
    assert_equals "0" "1" "version_check_is_outdated funcao existe"
fi

# ============================================================================
# Tests: version_check_compare
# ============================================================================

test_section "version_check_compare - Comparacao semver"

if type version_check_compare &>/dev/null; then
    # Test: v1 menor que v2
    result=$(version_check_compare "4.1.0" "4.3.0")
    assert_equals "-1" "$result" "4.1.0 < 4.3.0 retorna -1"

    # Test: versoes iguais
    result=$(version_check_compare "4.3.0" "4.3.0")
    assert_equals "0" "$result" "4.3.0 == 4.3.0 retorna 0"

    # Test: v1 maior que v2
    result=$(version_check_compare "4.3.0" "4.1.0")
    assert_equals "1" "$result" "4.3.0 > 4.1.0 retorna 1"

    # Test: diferenca no patch
    result=$(version_check_compare "4.3.0" "4.3.1")
    assert_equals "-1" "$result" "4.3.0 < 4.3.1 retorna -1"

    # Test: diferenca no major
    result=$(version_check_compare "3.9.9" "4.0.0")
    assert_equals "-1" "$result" "3.9.9 < 4.0.0 retorna -1"

    # Test: minor vs patch
    result=$(version_check_compare "4.2.0" "4.1.9")
    assert_equals "1" "$result" "4.2.0 > 4.1.9 retorna 1"

    # Test: versao com numeros grandes
    result=$(version_check_compare "10.20.30" "10.20.30")
    assert_equals "0" "$result" "10.20.30 == 10.20.30 retorna 0"
else
    assert_equals "0" "1" "version_check_compare nao disponivel"
fi
