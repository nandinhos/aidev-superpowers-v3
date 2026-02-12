#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Deploy Sync Tests (TDD)
# ============================================================================
# Testes para o modulo de sincronizacao local/global
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source module under test
if [ -f "$ROOT_DIR/lib/deploy-sync.sh" ]; then
    # Source core first for utility functions
    source "$ROOT_DIR/lib/core.sh" 2>/dev/null || true
    source "$ROOT_DIR/lib/deploy-sync.sh"
fi

# ============================================================================
# Test Setup / Teardown
# ============================================================================

TEST_TEMP_DIR=""
TEST_LOCAL_DIR=""
TEST_GLOBAL_DIR=""

setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    TEST_LOCAL_DIR="$TEST_TEMP_DIR/local"
    TEST_GLOBAL_DIR="$TEST_TEMP_DIR/global"

    mkdir -p "$TEST_LOCAL_DIR/bin"
    mkdir -p "$TEST_LOCAL_DIR/lib"
    mkdir -p "$TEST_GLOBAL_DIR/bin"
    mkdir -p "$TEST_GLOBAL_DIR/lib"

    # Override global dir for testing
    AIDEV_GLOBAL_DIR="$TEST_GLOBAL_DIR"
}

cleanup_test_env() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper: cria arquivos de teste sincronizados
create_synced_files() {
    echo "#!/bin/bash" > "$TEST_LOCAL_DIR/bin/aidev"
    echo "#!/bin/bash" > "$TEST_GLOBAL_DIR/bin/aidev"
    echo "# core" > "$TEST_LOCAL_DIR/lib/core.sh"
    echo "# core" > "$TEST_GLOBAL_DIR/lib/core.sh"
    echo "3.10.2" > "$TEST_LOCAL_DIR/VERSION"
    echo "3.10.2" > "$TEST_GLOBAL_DIR/VERSION"
}

# Helper: cria divergencia
create_divergent_files() {
    echo "#!/bin/bash v2" > "$TEST_LOCAL_DIR/bin/aidev"
    echo "#!/bin/bash v1" > "$TEST_GLOBAL_DIR/bin/aidev"
    echo "# core v2" > "$TEST_LOCAL_DIR/lib/core.sh"
    echo "# core v1" > "$TEST_GLOBAL_DIR/lib/core.sh"
    echo "3.11.0" > "$TEST_LOCAL_DIR/VERSION"
    echo "3.10.2" > "$TEST_GLOBAL_DIR/VERSION"
}

# ============================================================================
# Testes: deploy_sync_check_divergence
# ============================================================================

test_section "deploy_sync_check_divergence - Deteccao de Divergencia"

# Test 1: Retorna 1 quando global nao existe
setup_test_env
AIDEV_GLOBAL_DIR="/tmp/nonexistent-dir-$$"
result=$(deploy_sync_check_divergence "$TEST_LOCAL_DIR" 2>&1)
exit_code=$?
assert_equals "1" "$exit_code" "Retorna 1 quando dir global nao existe"
cleanup_test_env

# Test 2: Retorna 0 quando diretorio e o mesmo
setup_test_env
AIDEV_GLOBAL_DIR="$TEST_LOCAL_DIR"
deploy_sync_check_divergence "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "0" "$exit_code" "Retorna 0 quando local = global (mesmo diretorio)"
cleanup_test_env

# Test 3: Retorna 0 quando arquivos estao sincronizados
setup_test_env
create_synced_files
deploy_sync_check_divergence "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "0" "$exit_code" "Retorna 0 quando arquivos estao sincronizados"
cleanup_test_env

# Test 4: Retorna 1 quando ha divergencia
setup_test_env
create_divergent_files
deploy_sync_check_divergence "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "1" "$exit_code" "Retorna 1 quando ha divergencia"
cleanup_test_env

# Test 5: Output contem alerta de divergencia
setup_test_env
create_divergent_files
result=$(deploy_sync_check_divergence "$TEST_LOCAL_DIR" 2>&1)
assert_contains "$result" "DIVERGÊNCIA" "Output contem alerta de divergencia"
cleanup_test_env

# Test 6: Output lista arquivos divergentes
setup_test_env
create_divergent_files
result=$(deploy_sync_check_divergence "$TEST_LOCAL_DIR" 2>&1)
assert_contains "$result" "bin/aidev" "Output lista bin/aidev como divergente"
cleanup_test_env

# Test 7: Detecta arquivo novo (existe local, nao existe global)
setup_test_env
create_synced_files
echo "# new module" > "$TEST_LOCAL_DIR/lib/cache.sh"
# Nao cria no global
deploy_sync_check_divergence "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "1" "$exit_code" "Detecta arquivo novo que falta no global"
cleanup_test_env

# ============================================================================
# Testes: deploy_sync_to_global
# ============================================================================

test_section "deploy_sync_to_global - Sincronizacao"

# Test 8: Retorna 1 quando global nao existe
setup_test_env
AIDEV_GLOBAL_DIR="/tmp/nonexistent-dir-$$"
deploy_sync_to_global "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "1" "$exit_code" "Sync retorna 1 quando dir global nao existe"
cleanup_test_env

# Test 9: Retorna 0 quando local = global
setup_test_env
AIDEV_GLOBAL_DIR="$TEST_LOCAL_DIR"
deploy_sync_to_global "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "0" "$exit_code" "Sync retorna 0 quando local = global"
cleanup_test_env

# Test 10: Sincroniza arquivos divergentes
setup_test_env
create_divergent_files
deploy_sync_to_global "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "0" "$exit_code" "Sync retorna 0 apos sincronizar"
# Verifica se conteudo ficou igual
local_content_check=$(cat "$TEST_LOCAL_DIR/bin/aidev")
global_content_check=$(cat "$TEST_GLOBAL_DIR/bin/aidev")
assert_equals "$local_content_check" "$global_content_check" "bin/aidev sincronizado corretamente"
cleanup_test_env

# Test 11: Cria timestamp de sync
setup_test_env
create_divergent_files
deploy_sync_to_global "$TEST_LOCAL_DIR" >/dev/null 2>&1
assert_file_exists "$TEST_GLOBAL_DIR/.last_sync_timestamp" "Cria arquivo de timestamp apos sync"
cleanup_test_env

# Test 12: Dry-run nao altera arquivos
setup_test_env
create_divergent_files
original_content=$(cat "$TEST_GLOBAL_DIR/bin/aidev")
deploy_sync_to_global "$TEST_LOCAL_DIR" "--dry-run" >/dev/null 2>&1
after_content=$(cat "$TEST_GLOBAL_DIR/bin/aidev")
assert_equals "$original_content" "$after_content" "Dry-run nao altera arquivos"
cleanup_test_env

# Test 13: Sync nao copia arquivo que nao existe localmente
setup_test_env
create_synced_files
# Nao criamos lib/cache.sh localmente, so globalmente
echo "# old cache" > "$TEST_GLOBAL_DIR/lib/cache.sh"
deploy_sync_to_global "$TEST_LOCAL_DIR" >/dev/null 2>&1
exit_code=$?
assert_equals "0" "$exit_code" "Sync ignora arquivos que nao existem localmente"
cleanup_test_env

# ============================================================================
# Testes: deploy_sync_check_on_init
# ============================================================================

test_section "deploy_sync_check_on_init - Verificacao na Inicializacao"

# Test 14: Nao alerta quando esta no diretorio global
setup_test_env
AIDEV_GLOBAL_DIR="$TEST_GLOBAL_DIR"
cd "$TEST_GLOBAL_DIR"
result=$(deploy_sync_check_on_init 2>&1)
exit_code=$?
assert_equals "0" "$exit_code" "Nao verifica quando esta no dir global"
cd "$ROOT_DIR"
cleanup_test_env

# Test 15: Alerta quando ha divergencia em arquivo critico
setup_test_env
create_divergent_files
cd "$TEST_LOCAL_DIR"
result=$(deploy_sync_check_on_init 2>&1)
assert_contains "$result" "ALERTA" "Exibe alerta de divergencia na inicializacao"
cd "$ROOT_DIR"
cleanup_test_env

# Test 16: Nao alerta quando esta sincronizado
setup_test_env
create_synced_files
cd "$TEST_LOCAL_DIR"
result=$(deploy_sync_check_on_init 2>&1)
# Resultado deve ser vazio (sem alerta)
if [ -z "$result" ]; then
    ((TESTS_TOTAL++))
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} Nao alerta quando esta sincronizado"
else
    ((TESTS_TOTAL++))
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗${NC} Nao alerta quando esta sincronizado (output inesperado: $result)"
fi
cd "$ROOT_DIR"
cleanup_test_env

# ============================================================================
# Testes: deploy_sync_status
# ============================================================================

test_section "deploy_sync_status - Status da Sincronizacao"

# Test 17: Mostra status quando global existe
setup_test_env
create_synced_files
cd "$TEST_LOCAL_DIR"
result=$(deploy_sync_status 2>&1)
assert_contains "$result" "Status da Sincronização" "Exibe titulo do status"
cd "$ROOT_DIR"
cleanup_test_env

# Test 18: Retorna erro quando global nao existe
setup_test_env
AIDEV_GLOBAL_DIR="/tmp/nonexistent-dir-$$"
cd "$TEST_LOCAL_DIR"
deploy_sync_status >/dev/null 2>&1
exit_code=$?
assert_equals "1" "$exit_code" "Retorna 1 quando global nao existe no status"
cd "$ROOT_DIR"
cleanup_test_env

# ============================================================================
# Testes: deploy_sync_after_release
# ============================================================================

test_section "deploy_sync_after_release - Hook de Release"

# Test 19: Sincroniza apos release
setup_test_env
create_divergent_files
echo "3.11.0" > "$TEST_LOCAL_DIR/VERSION"
cd "$TEST_LOCAL_DIR"
deploy_sync_after_release >/dev/null 2>&1
exit_code=$?
assert_equals "0" "$exit_code" "Hook de release retorna 0 apos sync"
cd "$ROOT_DIR"
cleanup_test_env

# Test 20: Arquivos ficam iguais apos release sync
setup_test_env
create_divergent_files
cd "$TEST_LOCAL_DIR"
deploy_sync_after_release >/dev/null 2>&1
local_ver=$(cat "$TEST_LOCAL_DIR/VERSION")
global_ver=$(cat "$TEST_GLOBAL_DIR/VERSION")
assert_equals "$local_ver" "$global_ver" "VERSION sincronizado apos release"
cd "$ROOT_DIR"
cleanup_test_env

# ============================================================================
# Testes: AIDEV_SYNC_FILES
# ============================================================================

test_section "AIDEV_SYNC_FILES - Lista de Arquivos Criticos"

# Test 21: Lista contem bin/aidev
if [[ " ${AIDEV_SYNC_FILES[*]} " == *" bin/aidev "* ]]; then
    ((TESTS_TOTAL++))
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} Lista contem bin/aidev"
else
    ((TESTS_TOTAL++))
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗${NC} Lista contem bin/aidev"
fi

# Test 22: Lista contem VERSION
if [[ " ${AIDEV_SYNC_FILES[*]} " == *" VERSION "* ]]; then
    ((TESTS_TOTAL++))
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} Lista contem VERSION"
else
    ((TESTS_TOTAL++))
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗${NC} Lista contem VERSION"
fi

# Test 23: Lista contem lib/core.sh
if [[ " ${AIDEV_SYNC_FILES[*]} " == *" lib/core.sh "* ]]; then
    ((TESTS_TOTAL++))
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} Lista contem lib/core.sh"
else
    ((TESTS_TOTAL++))
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗${NC} Lista contem lib/core.sh"
fi

# Test 24: deploy-sync.sh inclui a si proprio na lista
if [[ " ${AIDEV_SYNC_FILES[*]} " == *" lib/deploy-sync.sh "* ]]; then
    ((TESTS_TOTAL++))
    ((TESTS_PASSED++))
    echo -e "  ${GREEN}✓${NC} Lista contem lib/deploy-sync.sh"
else
    ((TESTS_TOTAL++))
    ((TESTS_FAILED++))
    echo -e "  ${RED}✗${NC} Lista NAO contem lib/deploy-sync.sh (deveria para auto-sync)"
fi

# ============================================================================
# Report
# ============================================================================

print_report
