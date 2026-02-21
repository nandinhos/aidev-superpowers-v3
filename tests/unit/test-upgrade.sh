#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Upgrade Module Tests (TDD RED Phase)
# ============================================================================
# Testes para o modulo de upgrade seguro
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
if [ -f "$ROOT_DIR/lib/upgrade.sh" ]; then
    source "$ROOT_DIR/lib/upgrade.sh"
fi

# ============================================================================
# Test Setup
# ============================================================================

TEST_TEMP_DIR=""

setup_test_env() {
    TEST_TEMP_DIR=$(mktemp -d)

    # Simular projeto com .aidev/
    mkdir -p "$TEST_TEMP_DIR/.aidev/agents"
    mkdir -p "$TEST_TEMP_DIR/.aidev/skills/brainstorming"
    mkdir -p "$TEST_TEMP_DIR/.aidev/rules"
    mkdir -p "$TEST_TEMP_DIR/.aidev/state"
    mkdir -p "$TEST_TEMP_DIR/.aidev/mcp"
    mkdir -p "$TEST_TEMP_DIR/.aidev/.cache"
    mkdir -p "$TEST_TEMP_DIR/.aidev/backups"
    mkdir -p "$TEST_TEMP_DIR/.aidev/plans/backlog"

    # Arquivos de agents
    echo "# Orchestrator Agent - original template" > "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md"
    echo "# Backend Agent" > "$TEST_TEMP_DIR/.aidev/agents/backend.md"

    # Arquivo de rules
    echo "# Generic Rules" > "$TEST_TEMP_DIR/.aidev/rules/generic.md"

    # Arquivo de skills
    echo "# Brainstorming SKILL" > "$TEST_TEMP_DIR/.aidev/skills/brainstorming/SKILL.md"

    # Arquivo de MCP
    echo '{"mcpServers":{}}' > "$TEST_TEMP_DIR/.aidev/mcp/claude-code.json"

    # Arquivo de state
    echo '{"version":"4.3.0"}' > "$TEST_TEMP_DIR/.aidev/state/unified.json"

    # Arquivo de plans (user content)
    echo "# Meu plano custom" > "$TEST_TEMP_DIR/.aidev/plans/backlog/meu-plano.md"

    # MANIFEST.json
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
# Tests: upgrade_compute_checksum
# ============================================================================

test_section "upgrade_compute_checksum - Hash SHA256"

# Test: funcao existe
if type upgrade_compute_checksum &>/dev/null; then
    assert_equals "0" "0" "upgrade_compute_checksum funcao existe"
else
    assert_equals "0" "1" "upgrade_compute_checksum funcao existe"
fi

# Test: retorna hash consistente para mesmo conteudo
setup_test_env
if type upgrade_compute_checksum &>/dev/null; then
    hash1=$(upgrade_compute_checksum "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md")
    hash2=$(upgrade_compute_checksum "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md")
    assert_equals "$hash1" "$hash2" "mesmo arquivo gera mesmo hash"
else
    assert_equals "0" "1" "mesmo arquivo gera mesmo hash"
fi

# Test: conteudos diferentes geram hashes diferentes
if type upgrade_compute_checksum &>/dev/null; then
    hash_orch=$(upgrade_compute_checksum "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md")
    hash_back=$(upgrade_compute_checksum "$TEST_TEMP_DIR/.aidev/agents/backend.md")
    result=$( [ "$hash_orch" != "$hash_back" ] && echo "different" || echo "same" )
    assert_equals "different" "$result" "conteudos diferentes geram hashes diferentes"
else
    assert_equals "0" "1" "conteudos diferentes geram hashes diferentes"
fi

# Test: hash nao eh vazio
if type upgrade_compute_checksum &>/dev/null; then
    hash=$(upgrade_compute_checksum "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md")
    assert_not_empty "$hash" "hash nao eh vazio"
else
    assert_equals "0" "1" "hash nao eh vazio"
fi

# Test: arquivo inexistente retorna erro
if type upgrade_compute_checksum &>/dev/null; then
    upgrade_compute_checksum "/tmp/nao_existe_$(date +%s)" 2>/dev/null
    assert_equals "1" "$?" "arquivo inexistente retorna erro"
else
    assert_equals "0" "1" "arquivo inexistente retorna erro"
fi
teardown_test_env

# ============================================================================
# Tests: upgrade_compare_with_template
# ============================================================================

test_section "upgrade_compare_with_template - Comparacao"

setup_test_env
if type upgrade_compare_with_template &>/dev/null; then
    # Test: arquivo identico ao template
    echo "conteudo identico" > "$TEST_TEMP_DIR/file_a.md"
    echo "conteudo identico" > "$TEST_TEMP_DIR/file_b.md"
    result=$(upgrade_compare_with_template "$TEST_TEMP_DIR/file_a.md" "$TEST_TEMP_DIR/file_b.md")
    assert_equals "identical" "$result" "arquivos identicos retorna identical"

    # Test: arquivo modificado
    echo "conteudo original" > "$TEST_TEMP_DIR/original.md"
    echo "conteudo customizado pelo usuario" > "$TEST_TEMP_DIR/customizado.md"
    result=$(upgrade_compare_with_template "$TEST_TEMP_DIR/customizado.md" "$TEST_TEMP_DIR/original.md")
    assert_equals "modified" "$result" "arquivo customizado retorna modified"

    # Test: arquivo inexistente
    result=$(upgrade_compare_with_template "/tmp/nao_existe_$(date +%s)" "$TEST_TEMP_DIR/original.md")
    assert_equals "missing" "$result" "arquivo inexistente retorna missing"
else
    assert_equals "0" "1" "upgrade_compare_with_template nao disponivel"
    assert_equals "0" "1" "upgrade_compare_with_template nao disponivel (modified)"
    assert_equals "0" "1" "upgrade_compare_with_template nao disponivel (missing)"
fi
teardown_test_env

# ============================================================================
# Tests: upgrade_backup_full
# ============================================================================

test_section "upgrade_backup_full - Backup Expandido"

setup_test_env
if type upgrade_backup_full &>/dev/null; then
    # Test: cria backup de agents
    backup_dir=$(upgrade_backup_full "$TEST_TEMP_DIR")
    assert_dir_exists "$backup_dir/agents" "backup inclui agents/"

    # Test: cria backup de skills
    assert_dir_exists "$backup_dir/skills" "backup inclui skills/"

    # Test: cria backup de rules
    assert_dir_exists "$backup_dir/rules" "backup inclui rules/"

    # Test: cria backup de mcp
    assert_dir_exists "$backup_dir/mcp" "backup inclui mcp/"

    # Test: NAO faz backup de state (runtime, nao precisa)
    result=$( [ -d "$backup_dir/state" ] && echo "exists" || echo "not_exists" )
    assert_equals "not_exists" "$result" "backup NAO inclui state/ (runtime)"

    # Test: NAO faz backup de plans (conteudo do usuario, nao eh tocado)
    result=$( [ -d "$backup_dir/plans" ] && echo "exists" || echo "not_exists" )
    assert_equals "not_exists" "$result" "backup NAO inclui plans/ (conteudo usuario)"

    # Test: backup dir retornado nao eh vazio
    assert_not_empty "$backup_dir" "backup_dir retornado nao eh vazio"
else
    assert_equals "0" "1" "upgrade_backup_full nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: upgrade_should_overwrite
# ============================================================================

test_section "upgrade_should_overwrite - Decisao de Escrita"

setup_test_env
if type upgrade_should_overwrite &>/dev/null && [ -f "$TEST_TEMP_DIR/MANIFEST.json" ]; then
    # Carregar manifesto
    AIDEV_ROOT_DIR="$TEST_TEMP_DIR"
    manifest_load 2>/dev/null

    # Test: arquivo de state nunca eh sobrescrito
    upgrade_should_overwrite "$TEST_TEMP_DIR/.aidev/state/unified.json" "$TEST_TEMP_DIR" 2>/dev/null
    assert_equals "1" "$?" "state/unified.json nunca eh sobrescrito"

    # Test: arquivo de plans nunca eh tocado
    upgrade_should_overwrite "$TEST_TEMP_DIR/.aidev/plans/backlog/meu-plano.md" "$TEST_TEMP_DIR" 2>/dev/null
    assert_equals "1" "$?" "plans/** nunca eh tocado"

    # Test: arquivo inexistente pode ser escrito
    upgrade_should_overwrite "$TEST_TEMP_DIR/.aidev/agents/novo-agent.md" "$TEST_TEMP_DIR" 2>/dev/null
    assert_equals "0" "$?" "arquivo inexistente pode ser escrito"

    # Test: arquivo identico ao template eh sobrescrito (atualizacao silenciosa)
    echo "conteudo template" > "$TEST_TEMP_DIR/.aidev/agents/test-agent.md"
    echo "conteudo template" > "$TEST_TEMP_DIR/template_output.md"
    upgrade_should_overwrite "$TEST_TEMP_DIR/.aidev/agents/test-agent.md" "$TEST_TEMP_DIR" "$TEST_TEMP_DIR/template_output.md" 2>/dev/null
    assert_equals "0" "$?" "arquivo identico ao template eh sobrescrito"

    # Test: arquivo customizado NAO eh sobrescrito
    echo "conteudo original do template" > "$TEST_TEMP_DIR/.aidev/agents/custom-agent.md"
    echo "# Customizado pelo usuario" >> "$TEST_TEMP_DIR/.aidev/agents/custom-agent.md"
    echo "conteudo original do template" > "$TEST_TEMP_DIR/template_original.md"
    upgrade_should_overwrite "$TEST_TEMP_DIR/.aidev/agents/custom-agent.md" "$TEST_TEMP_DIR" "$TEST_TEMP_DIR/template_original.md" 2>/dev/null
    assert_equals "1" "$?" "arquivo customizado NAO eh sobrescrito"
else
    assert_equals "0" "1" "upgrade_should_overwrite nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: upgrade_dry_run
# ============================================================================

test_section "upgrade_dry_run - Preview sem Modificar"

setup_test_env
if type upgrade_dry_run &>/dev/null; then
    # Test: dry_run nao modifica arquivos
    before_hash=$(sha256sum "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md" 2>/dev/null | cut -d' ' -f1)
    upgrade_dry_run "$TEST_TEMP_DIR" > /dev/null 2>&1
    after_hash=$(sha256sum "$TEST_TEMP_DIR/.aidev/agents/orchestrator.md" 2>/dev/null | cut -d' ' -f1)
    assert_equals "$before_hash" "$after_hash" "dry_run nao modifica arquivos"

    # Test: dry_run produz output
    output=$(upgrade_dry_run "$TEST_TEMP_DIR" 2>&1)
    result=$( [ -n "$output" ] && echo "has_output" || echo "empty" )
    assert_equals "has_output" "$result" "dry_run produz output"
else
    assert_equals "0" "1" "upgrade_dry_run nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: upgrade_record_checksums
# ============================================================================

test_section "upgrade_record_checksums - Registro de Checksums"

setup_test_env
if type upgrade_record_checksums &>/dev/null; then
    # Test: cria checksums.json
    upgrade_record_checksums "$TEST_TEMP_DIR"
    assert_file_exists "$TEST_TEMP_DIR/.aidev/state/checksums.json" "checksums.json eh criado"

    # Test: checksums.json eh JSON valido
    if [ -f "$TEST_TEMP_DIR/.aidev/state/checksums.json" ]; then
        jq empty "$TEST_TEMP_DIR/.aidev/state/checksums.json" 2>/dev/null
        assert_equals "0" "$?" "checksums.json eh JSON valido"
    fi

    # Test: contem entrada para orchestrator.md
    if [ -f "$TEST_TEMP_DIR/.aidev/state/checksums.json" ]; then
        entry=$(jq -r '.files[".aidev/agents/orchestrator.md"].checksum // empty' "$TEST_TEMP_DIR/.aidev/state/checksums.json")
        assert_not_empty "$entry" "checksums.json tem entrada para orchestrator.md"
    fi
else
    assert_equals "0" "1" "upgrade_record_checksums nao disponivel"
fi
teardown_test_env

# ============================================================================
# Tests: self_upgrade_detect_drift
# ============================================================================

test_section "self_upgrade_detect_drift - Deteccao de Divergencia"

setup_test_env

# Prepara estrutura de source e global simulados
SRC_DIR=$(mktemp -d)
GLB_DIR=$(mktemp -d)
mkdir -p "$SRC_DIR/lib" "$SRC_DIR/bin"
mkdir -p "$GLB_DIR/lib" "$GLB_DIR/bin"

# Popula lib/ identica nos dois
echo "# lib script" > "$SRC_DIR/lib/core.sh"
cp "$SRC_DIR/lib/core.sh" "$GLB_DIR/lib/core.sh"

# Popula bin/aidev identico nos dois
echo "#!/bin/bash" > "$SRC_DIR/bin/aidev"
cp "$SRC_DIR/bin/aidev" "$GLB_DIR/bin/aidev"

if type self_upgrade_detect_drift &>/dev/null; then
    # Test: retorna 0 quando source e global sao identicos
    count=$(self_upgrade_detect_drift "$SRC_DIR" "$GLB_DIR")
    assert_equals "0" "$count" "retorna 0 quando source e global sao identicos"

    # Test: detecta divergencia em bin/aidev
    echo "# fix adicionado" >> "$SRC_DIR/bin/aidev"
    count=$(self_upgrade_detect_drift "$SRC_DIR" "$GLB_DIR")
    result=$( [ "$count" -gt 0 ] && echo "divergente" || echo "igual" )
    assert_equals "divergente" "$result" "detecta divergencia em bin/aidev"

    # Restaura bin/aidev identico
    cp "$GLB_DIR/bin/aidev" "$SRC_DIR/bin/aidev"

    # Test: detecta divergencia em lib/
    echo "# fix em lib" >> "$SRC_DIR/lib/core.sh"
    count=$(self_upgrade_detect_drift "$SRC_DIR" "$GLB_DIR")
    result=$( [ "$count" -gt 0 ] && echo "divergente" || echo "igual" )
    assert_equals "divergente" "$result" "detecta divergencia em lib/"

    # Test: retorna valor numerico (nao vazio)
    assert_not_empty "$count" "retorna valor numerico"
else
    assert_equals "0" "1" "self_upgrade_detect_drift nao disponivel"
    assert_equals "0" "1" "self_upgrade_detect_drift nao disponivel (bin)"
    assert_equals "0" "1" "self_upgrade_detect_drift nao disponivel (lib)"
    assert_equals "0" "1" "self_upgrade_detect_drift nao disponivel (not_empty)"
fi

rm -rf "$SRC_DIR" "$GLB_DIR"
teardown_test_env
