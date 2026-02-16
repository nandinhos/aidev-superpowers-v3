#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Migration Tests (TDD RED Phase)
# ============================================================================
# Testes para o modulo de migracao incremental e MANIFEST.local.json
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source test framework
source "$SCRIPT_DIR/../test-runner.sh"

# Source modules under test
if [ -f "$ROOT_DIR/lib/core.sh" ]; then
    source "$ROOT_DIR/lib/core.sh"
fi
if [ -f "$ROOT_DIR/lib/file-ops.sh" ]; then
    source "$ROOT_DIR/lib/file-ops.sh"
fi
if [ -f "$ROOT_DIR/lib/state.sh" ]; then
    source "$ROOT_DIR/lib/state.sh"
fi
if [ -f "$ROOT_DIR/lib/migration.sh" ]; then
    source "$ROOT_DIR/lib/migration.sh"
fi

# ============================================================================
# Test Setup
# ============================================================================

TEST_TEMP_DIR=""

setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)
    mkdir -p "$TEST_TEMP_DIR/.aidev/state"
    # Cria unified.json minimo
    cat > "$TEST_TEMP_DIR/.aidev/state/unified.json" << 'EOF'
{
  "version": "3.2.0",
  "session": {
    "id": "test-session",
    "started_at": "2026-02-16T00:00:00",
    "last_activity": "2026-02-16T00:00:00",
    "project_name": "test-project",
    "stack": "generic",
    "maturity": "greenfield"
  },
  "active_skill": null,
  "active_agent": null,
  "checkpoints": {},
  "artifacts": [],
  "agent_queue": [],
  "confidence_log": [],
  "rollback_stack": []
}
EOF
    CLI_INSTALL_PATH="$TEST_TEMP_DIR"
    AIDEV_ROOT_DIR="$ROOT_DIR"
}

teardown_test_env() {
    if [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# ============================================================================
# Tests: Funcoes existem
# ============================================================================

test_section "migration - Funcoes existem"

for fn in migration_get_project_version migration_needed migration_list_steps migration_execute migration_stamp; do
    if type "$fn" &>/dev/null; then
        assert_equals "0" "0" "$fn funcao existe"
    else
        assert_equals "0" "1" "$fn funcao existe"
    fi
done

# ============================================================================
# Tests: migration_stamp
# ============================================================================

test_section "migration_stamp - Grava versao no projeto"

setup_test_env
if type migration_stamp &>/dev/null; then
    # Test: cria MANIFEST.local.json
    migration_stamp "$TEST_TEMP_DIR" 2>/dev/null
    if [ -f "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json" ]; then
        assert_equals "0" "0" "MANIFEST.local.json criado"

        # Verifica campos obrigatorios
        if command -v jq &>/dev/null; then
            pv=$(jq -r '.project_version // empty' "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json")
            assert_not_empty "$pv" "MANIFEST.local.json tem project_version"

            cli_v=$(jq -r '.cli_version_at_init // empty' "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json")
            assert_not_empty "$cli_v" "MANIFEST.local.json tem cli_version_at_init"

            lu=$(jq -r '.last_upgrade // empty' "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json")
            assert_not_empty "$lu" "MANIFEST.local.json tem last_upgrade"
        fi
    else
        assert_equals "0" "1" "MANIFEST.local.json criado"
    fi

    # Test: atualiza versao em stamp subsequente
    migration_stamp "$TEST_TEMP_DIR" 2>/dev/null
    if command -v jq &>/dev/null && [ -f "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json" ]; then
        pv=$(jq -r '.project_version // empty' "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json")
        assert_equals "$AIDEV_VERSION" "$pv" "stamp atualiza project_version para versao CLI atual"
    fi
else
    assert_equals "0" "1" "migration_stamp nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: migration_get_project_version
# ============================================================================

test_section "migration_get_project_version - Le versao do projeto"

setup_test_env
if type migration_get_project_version &>/dev/null && type migration_stamp &>/dev/null; then
    # Test: retorna unknown se MANIFEST.local.json nao existe
    result=$(migration_get_project_version "$TEST_TEMP_DIR")
    assert_equals "unknown" "$result" "retorna unknown sem MANIFEST.local.json"

    # Test: retorna versao apos stamp
    migration_stamp "$TEST_TEMP_DIR" 2>/dev/null
    result=$(migration_get_project_version "$TEST_TEMP_DIR")
    assert_equals "$AIDEV_VERSION" "$result" "retorna versao apos stamp"
else
    assert_equals "0" "1" "migration_get_project_version nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: migration_needed
# ============================================================================

test_section "migration_needed - Detecta necessidade de migracao"

setup_test_env
if type migration_needed &>/dev/null && type migration_stamp &>/dev/null; then
    # Test: migracao necessaria se MANIFEST.local.json nao existe
    migration_needed "$TEST_TEMP_DIR" 2>/dev/null
    assert_equals "0" "$?" "migracao necessaria sem MANIFEST.local.json"

    # Test: migracao NAO necessaria se versao igual
    migration_stamp "$TEST_TEMP_DIR" 2>/dev/null
    migration_needed "$TEST_TEMP_DIR" 2>/dev/null
    assert_equals "1" "$?" "migracao NAO necessaria com versao igual"

    # Test: migracao necessaria se versao diferente
    if command -v jq &>/dev/null; then
        local tmp_file=$(mktemp)
        jq '.project_version = "4.0.0"' "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json" > "$tmp_file" && \
            mv "$tmp_file" "$TEST_TEMP_DIR/.aidev/MANIFEST.local.json"
        migration_needed "$TEST_TEMP_DIR" 2>/dev/null
        assert_equals "0" "$?" "migracao necessaria com versao antiga"
    fi
else
    assert_equals "0" "1" "migration_needed nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: migration_list_steps
# ============================================================================

test_section "migration_list_steps - Lista passos de migracao"

setup_test_env
if type migration_list_steps &>/dev/null; then
    # Cria scripts de migracao fake
    mkdir -p "$ROOT_DIR/migrations"

    # Cria migrations temporarias para teste
    MIGRATION_TEST_DIR=$(mktemp -d)
    mkdir -p "$MIGRATION_TEST_DIR"
    echo '#!/bin/bash' > "$MIGRATION_TEST_DIR/4.1.0-add-feature.sh"
    echo '#!/bin/bash' > "$MIGRATION_TEST_DIR/4.2.0-update-config.sh"
    echo '#!/bin/bash' > "$MIGRATION_TEST_DIR/4.3.0-refactor-state.sh"

    # Test: lista migracoes entre versoes
    AIDEV_MIGRATIONS_DIR="$MIGRATION_TEST_DIR"
    result=$(migration_list_steps "4.0.0" "4.3.0")
    assert_contains "$result" "4.1.0" "lista inclui migracao 4.1.0"
    assert_contains "$result" "4.2.0" "lista inclui migracao 4.2.0"
    assert_contains "$result" "4.3.0" "lista inclui migracao 4.3.0"

    # Test: lista vazia quando versao ja atualizada
    result=$(migration_list_steps "4.3.0" "4.3.0")
    if [ -z "$result" ]; then
        assert_equals "0" "0" "lista vazia quando ja atualizado"
    else
        assert_equals "" "$result" "lista vazia quando ja atualizado"
    fi

    rm -rf "$MIGRATION_TEST_DIR"
else
    assert_equals "0" "1" "migration_list_steps nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: migration_execute
# ============================================================================

test_section "migration_execute - Executa migracoes"

setup_test_env
if type migration_execute &>/dev/null; then
    # Cria migracao que cria um arquivo marker
    MIGRATION_TEST_DIR=$(mktemp -d)
    cat > "$MIGRATION_TEST_DIR/4.2.0-test-migration.sh" << 'MIGRATION'
#!/bin/bash
# Migracao de teste: cria arquivo marker
touch "${MIGRATION_INSTALL_PATH:-.}/.aidev/state/migrated-4.2.0"
MIGRATION
    chmod +x "$MIGRATION_TEST_DIR/4.2.0-test-migration.sh"

    AIDEV_MIGRATIONS_DIR="$MIGRATION_TEST_DIR"
    migration_execute "$TEST_TEMP_DIR" "4.1.0" "4.3.0" 2>/dev/null

    # Verifica que migracao rodou
    if [ -f "$TEST_TEMP_DIR/.aidev/state/migrated-4.2.0" ]; then
        assert_equals "0" "0" "migracao 4.2.0 executou com sucesso"
    else
        assert_equals "0" "1" "migracao 4.2.0 executou com sucesso"
    fi

    rm -rf "$MIGRATION_TEST_DIR"
else
    assert_equals "0" "1" "migration_execute nao disponivel"
fi
teardown_test_env
