#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Manifest Tests (TDD RED Phase)
# ============================================================================
# Testes para o modulo de manifesto de classificacao de arquivos
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source modules under test
if [ -f "$ROOT_DIR/lib/core.sh" ]; then
    source "$ROOT_DIR/lib/core.sh"
fi
if [ -f "$ROOT_DIR/lib/manifest.sh" ]; then
    source "$ROOT_DIR/lib/manifest.sh"
fi

# ============================================================================
# Test Setup
# ============================================================================

TEST_TEMP_DIR=""

setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    # Copiar MANIFEST.json para o temp dir
    if [ -f "$ROOT_DIR/MANIFEST.json" ]; then
        cp "$ROOT_DIR/MANIFEST.json" "$TEST_TEMP_DIR/MANIFEST.json"
    fi
}

teardown_test_env() {
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ============================================================================
# Tests: MANIFEST.json Structure
# ============================================================================

test_section "MANIFEST.json - Estrutura"

# Test: MANIFEST.json existe
assert_file_exists "$ROOT_DIR/MANIFEST.json" "MANIFEST.json existe na raiz do projeto"

# Test: MANIFEST.json eh JSON valido
if command -v jq &>/dev/null && [ -f "$ROOT_DIR/MANIFEST.json" ]; then
    result=$(jq empty "$ROOT_DIR/MANIFEST.json" 2>&1 && echo "valid" || echo "invalid")
    assert_equals "valid" "$result" "MANIFEST.json eh JSON valido"
else
    assert_equals "0" "1" "MANIFEST.json eh JSON valido (jq nao disponivel)"
fi

# Test: MANIFEST.json tem campo manifest_version
if command -v jq &>/dev/null && [ -f "$ROOT_DIR/MANIFEST.json" ]; then
    version=$(jq -r '.manifest_version // empty' "$ROOT_DIR/MANIFEST.json")
    assert_not_empty "$version" "MANIFEST.json tem manifest_version"
else
    assert_equals "0" "1" "MANIFEST.json tem manifest_version"
fi

# Test: MANIFEST.json tem campo categories
if command -v jq &>/dev/null && [ -f "$ROOT_DIR/MANIFEST.json" ]; then
    categories=$(jq -r '.categories | keys | length' "$ROOT_DIR/MANIFEST.json")
    assert_equals "6" "$categories" "MANIFEST.json tem 6 categorias"
else
    assert_equals "0" "1" "MANIFEST.json tem 6 categorias"
fi

# Test: MANIFEST.json tem campo files
if command -v jq &>/dev/null && [ -f "$ROOT_DIR/MANIFEST.json" ]; then
    files_count=$(jq -r '.files | keys | length' "$ROOT_DIR/MANIFEST.json")
    result=$( [ "$files_count" -gt 0 ] && echo "has_files" || echo "empty" )
    assert_equals "has_files" "$result" "MANIFEST.json tem entradas de arquivos"
else
    assert_equals "0" "1" "MANIFEST.json tem entradas de arquivos"
fi

# ============================================================================
# Tests: manifest_load
# ============================================================================

test_section "manifest_load - Carregamento"

# Test: funcao manifest_load existe
if type manifest_load &>/dev/null; then
    assert_equals "0" "0" "manifest_load funcao existe"
else
    assert_equals "0" "1" "manifest_load funcao existe"
fi

# Test: manifest_load carrega com sucesso
setup_test_env
if type manifest_load &>/dev/null && [ -f "$TEST_TEMP_DIR/MANIFEST.json" ]; then
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_load
    load_result=$?
    assert_equals "0" "$load_result" "manifest_load carrega sem erro"
else
    assert_equals "0" "1" "manifest_load carrega sem erro"
fi
teardown_test_env

# Test: manifest_load falha com arquivo inexistente
if type manifest_load &>/dev/null; then
    AIDEV_ROOT_DIR="/tmp/nao_existe_$(date +%s)"
    manifest_load 2>/dev/null
    load_result=$?
    assert_equals "1" "$load_result" "manifest_load falha com arquivo inexistente"
else
    assert_equals "0" "1" "manifest_load falha com arquivo inexistente"
fi

# ============================================================================
# Tests: manifest_get_policy
# ============================================================================

test_section "manifest_get_policy - Consulta de Politicas"

setup_test_env
if type manifest_load &>/dev/null && type manifest_get_policy &>/dev/null && [ -f "$TEST_TEMP_DIR/MANIFEST.json" ]; then
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_load

    # Test: template policy para agents
    policy=$(manifest_get_policy ".aidev/agents/orchestrator.md")
    assert_equals "overwrite_unless_customized" "$policy" "agents/*.md retorna policy template"

    # Test: template policy para skills
    policy=$(manifest_get_policy ".aidev/skills/brainstorming/SKILL.md")
    assert_equals "overwrite_unless_customized" "$policy" "skills/*/SKILL.md retorna policy template"

    # Test: template policy para rules
    policy=$(manifest_get_policy ".aidev/rules/generic.md")
    assert_equals "overwrite_unless_customized" "$policy" "rules/*.md retorna policy template"

    # Test: state policy
    policy=$(manifest_get_policy ".aidev/state/unified.json")
    assert_equals "never_overwrite" "$policy" "state/* retorna policy never_overwrite"

    # Test: generated policy para cache
    policy=$(manifest_get_policy ".aidev/.cache/activation_cache.json")
    assert_equals "regenerate_on_demand" "$policy" ".cache/* retorna policy regenerate"

    # Test: user policy para plans
    policy=$(manifest_get_policy ".aidev/plans/backlog/feature.md")
    assert_equals "never_touch" "$policy" "plans/** retorna policy never_touch"

    # Test: user policy para memory kb
    policy=$(manifest_get_policy ".aidev/memory/kb/lesson.md")
    assert_equals "never_touch" "$policy" "memory/kb/*.md retorna policy never_touch"

    # Test: core policy para bin
    policy=$(manifest_get_policy "bin/aidev")
    assert_equals "never_modify_in_project" "$policy" "bin/aidev retorna policy core"

    # Test: core policy para lib
    policy=$(manifest_get_policy "lib/core.sh")
    assert_equals "never_modify_in_project" "$policy" "lib/*.sh retorna policy core"

    # Test: arquivo desconhecido retorna unknown
    policy=$(manifest_get_policy "random/unknown/file.txt")
    assert_equals "unknown" "$policy" "arquivo desconhecido retorna unknown"
else
    assert_equals "0" "1" "manifest_get_policy nao disponivel (modulo nao carregado)"
fi
teardown_test_env

# ============================================================================
# Tests: manifest_is_protected
# ============================================================================

test_section "manifest_is_protected - Verificacao de Protecao"

setup_test_env
if type manifest_load &>/dev/null && type manifest_is_protected &>/dev/null && [ -f "$TEST_TEMP_DIR/MANIFEST.json" ]; then
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_load

    # Test: core eh protegido
    manifest_is_protected "bin/aidev"
    assert_equals "0" "$?" "bin/aidev eh protegido"

    # Test: state eh protegido
    manifest_is_protected ".aidev/state/unified.json"
    assert_equals "0" "$?" "state/unified.json eh protegido"

    # Test: user eh protegido
    manifest_is_protected ".aidev/plans/backlog/feature.md"
    assert_equals "0" "$?" "plans/** eh protegido"

    # Test: template NAO eh protegido
    manifest_is_protected ".aidev/agents/orchestrator.md"
    result=$?
    assert_equals "1" "$result" "agents/*.md NAO eh protegido (eh template)"

    # Test: generated NAO eh protegido
    manifest_is_protected ".aidev/.cache/activation_cache.json"
    result=$?
    assert_equals "1" "$result" ".cache/* NAO eh protegido (eh generated)"
else
    assert_equals "0" "1" "manifest_is_protected nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: manifest_validate
# ============================================================================

test_section "manifest_validate - Validacao"

setup_test_env
if type manifest_validate &>/dev/null; then
    # Test: MANIFEST.json valido
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    if [ -f "$TEST_TEMP_DIR/MANIFEST.json" ]; then
        manifest_validate
        assert_equals "0" "$?" "MANIFEST.json valido passa validacao"
    fi

    # Test: JSON malformado falha
    echo "{invalid json" > "$TEST_TEMP_DIR/MANIFEST.json"
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_validate 2>/dev/null
    assert_equals "1" "$?" "JSON malformado falha validacao"

    # Test: JSON sem manifest_version falha
    echo '{"files":{}}' > "$TEST_TEMP_DIR/MANIFEST.json"
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_validate 2>/dev/null
    assert_equals "1" "$?" "JSON sem manifest_version falha validacao"
else
    assert_equals "0" "1" "manifest_validate nao disponivel"
fi
teardown_test_env
