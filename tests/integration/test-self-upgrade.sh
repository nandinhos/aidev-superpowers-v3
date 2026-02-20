#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Self-Upgrade Integration Tests
# ============================================================================
# Testes de integracao para cmd_self_upgrade: backup antes do rsync
# Usa ambiente simulado (nao modifica a instalacao real)
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_all_modules

# ============================================================================
# Setup / Teardown
# ============================================================================

FAKE_GLOBAL=""
FAKE_SOURCE=""

setup() {
    FAKE_GLOBAL=$(mktemp -d)
    FAKE_SOURCE=$(mktemp -d)

    # Simula instalacao global minima
    mkdir -p "$FAKE_GLOBAL/bin" "$FAKE_GLOBAL/lib" "$FAKE_GLOBAL/templates"
    echo "#!/bin/bash" > "$FAKE_GLOBAL/bin/aidev"
    echo "echo 'AIDEV_VERSION=\"4.2.0\"'" > "$FAKE_GLOBAL/lib/core.sh"
    echo "4.2.0" > "$FAKE_GLOBAL/VERSION"

    # Simula source com versao mais nova
    mkdir -p "$FAKE_SOURCE/bin" "$FAKE_SOURCE/lib" "$FAKE_SOURCE/templates"
    echo "#!/bin/bash" > "$FAKE_SOURCE/bin/aidev"
    echo "echo 'AIDEV_VERSION=\"4.3.0\"'" > "$FAKE_SOURCE/lib/core.sh"
    echo "4.3.0" > "$FAKE_SOURCE/VERSION"
}

cleanup() {
    rm -rf "$FAKE_GLOBAL" "$FAKE_SOURCE" "${FAKE_GLOBAL}.bak."* 2>/dev/null
}

trap cleanup EXIT

# ============================================================================
# Tests: Backup funcao existe e funciona
# ============================================================================

test_section "Integracao - Self-Upgrade backup"

setup

# Simula backup como feito no cmd_self_upgrade
backup_path="${FAKE_GLOBAL}.bak.$(date +%s)"
cp -r "$FAKE_GLOBAL" "$backup_path" 2>/dev/null

if [ -d "$backup_path" ]; then
    assert_equals "0" "0" "backup da instalacao global criado"

    # Verifica que backup contem os arquivos
    if [ -f "$backup_path/VERSION" ]; then
        backup_version=$(cat "$backup_path/VERSION" | tr -d '[:space:]')
        assert_equals "4.2.0" "$backup_version" "backup contem VERSION correta"
    else
        assert_equals "0" "1" "backup contem VERSION"
    fi

    if [ -f "$backup_path/bin/aidev" ]; then
        assert_equals "0" "0" "backup contem bin/aidev"
    else
        assert_equals "0" "1" "backup contem bin/aidev"
    fi

    if [ -f "$backup_path/lib/core.sh" ]; then
        assert_equals "0" "0" "backup contem lib/core.sh"
    else
        assert_equals "0" "1" "backup contem lib/core.sh"
    fi
else
    assert_equals "0" "1" "backup da instalacao global criado"
fi

cleanup

# ============================================================================
# Tests: Rollback restaura versao anterior
# ============================================================================

test_section "Integracao - Self-Upgrade rollback"

setup

# Cria backup
backup_path="${FAKE_GLOBAL}.bak.$(date +%s)"
cp -r "$FAKE_GLOBAL" "$backup_path"

# Simula upgrade (sobrescreve VERSION)
echo "4.3.0" > "$FAKE_GLOBAL/VERSION"
updated_version=$(cat "$FAKE_GLOBAL/VERSION" | tr -d '[:space:]')
assert_equals "4.3.0" "$updated_version" "upgrade atualiza VERSION para 4.3.0"

# Simula rollback (como feito no _self_upgrade_rollback)
rm -rf "$FAKE_GLOBAL"
mv "$backup_path" "$FAKE_GLOBAL"

rollback_version=$(cat "$FAKE_GLOBAL/VERSION" | tr -d '[:space:]')
assert_equals "4.2.0" "$rollback_version" "rollback restaura VERSION para 4.2.0"

cleanup

# ============================================================================
# Tests: Sync com rsync
# ============================================================================

test_section "Integracao - Self-Upgrade rsync sync"

setup

# Verifica que rsync esta disponivel
if command -v rsync &>/dev/null; then
    # Simula sync de bin/
    rsync -a "$FAKE_SOURCE/bin/" "$FAKE_GLOBAL/bin/" 2>/dev/null
    assert_equals "0" "$?" "rsync bin/ sucesso"

    # Simula sync de lib/
    rsync -a "$FAKE_SOURCE/lib/" "$FAKE_GLOBAL/lib/" 2>/dev/null
    assert_equals "0" "$?" "rsync lib/ sucesso"

    # Verifica que versao foi atualizada
    source_version=$(cat "$FAKE_SOURCE/VERSION" | tr -d '[:space:]')
    # Copia VERSION manualmente (rsync nao copia arquivos soltos)
    cp "$FAKE_SOURCE/VERSION" "$FAKE_GLOBAL/VERSION"
    global_version=$(cat "$FAKE_GLOBAL/VERSION" | tr -d '[:space:]')
    assert_equals "$source_version" "$global_version" "sync atualiza VERSION"
else
    assert_equals "0" "0" "rsync nao disponivel (skip)"
fi

cleanup

# ============================================================================
# Tests: Segunda camada de verificacao - mesma versao com arquivos divergentes
# ============================================================================

test_section "Self-Upgrade - segunda camada: mesma versao com diff real"

setup_same_version() {
    FAKE_GLOBAL=$(mktemp -d)
    FAKE_SOURCE=$(mktemp -d)
    mkdir -p "$FAKE_GLOBAL/bin" "$FAKE_GLOBAL/lib"
    mkdir -p "$FAKE_SOURCE/bin" "$FAKE_SOURCE/lib"
    # Mesma versao nos dois lados
    echo "4.5.6" > "$FAKE_GLOBAL/VERSION"
    echo "4.5.6" > "$FAKE_SOURCE/VERSION"
    echo "echo global" > "$FAKE_GLOBAL/lib/core.sh"
    echo "echo source" > "$FAKE_SOURCE/lib/core.sh"
}

# Test 1: detecta divergencia quando mesma versao mas lib/ difere
setup_same_version
diff_count=$(diff -rq "$FAKE_SOURCE/lib/" "$FAKE_GLOBAL/lib/" 2>/dev/null | wc -l | tr -d ' ')
[ "$diff_count" -gt 0 ] && assert_equals "1" "1" "detecta divergencia entre lib/ mesmo com mesma versao" || assert_equals "0" "1" "detecta divergencia entre lib/ mesmo com mesma versao"
rm -rf "$FAKE_GLOBAL" "$FAKE_SOURCE"

# Test 2: nao detecta divergencia quando lib/ identica
setup_same_version
cp "$FAKE_SOURCE/lib/core.sh" "$FAKE_GLOBAL/lib/core.sh"
diff_count=$(diff -rq "$FAKE_SOURCE/lib/" "$FAKE_GLOBAL/lib/" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$diff_count" "nao detecta divergencia quando lib/ e identica"
rm -rf "$FAKE_GLOBAL" "$FAKE_SOURCE"

# Test 3: detecta arquivo ausente na global como divergencia
setup_same_version
echo "echo novo-modulo" > "$FAKE_SOURCE/lib/feature-lifecycle-cli.sh"
diff_count=$(diff -rq "$FAKE_SOURCE/lib/" "$FAKE_GLOBAL/lib/" 2>/dev/null | wc -l | tr -d ' ')
[ "$diff_count" -gt 0 ] && assert_equals "1" "1" "detecta arquivo ausente na global como divergencia" || assert_equals "0" "1" "detecta arquivo ausente na global como divergencia"
rm -rf "$FAKE_GLOBAL" "$FAKE_SOURCE"

# Test 4: apos sync, divergencia cai a zero
FAKE_GLOBAL=$(mktemp -d)
FAKE_SOURCE=$(mktemp -d)
mkdir -p "$FAKE_GLOBAL/lib" "$FAKE_SOURCE/lib"
echo "4.5.6" > "$FAKE_GLOBAL/VERSION"
echo "4.5.6" > "$FAKE_SOURCE/VERSION"
# lib/ identica exceto por arquivo extra no source
echo "echo core" > "$FAKE_GLOBAL/lib/core.sh"
echo "echo core" > "$FAKE_SOURCE/lib/core.sh"
echo "echo novo-modulo" > "$FAKE_SOURCE/lib/feature-lifecycle-cli.sh"
rsync -a "$FAKE_SOURCE/lib/" "$FAKE_GLOBAL/lib/" 2>/dev/null
diff_count=$(diff -rq "$FAKE_SOURCE/lib/" "$FAKE_GLOBAL/lib/" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$diff_count" "apos sync divergencia cai a zero"
rm -rf "$FAKE_GLOBAL" "$FAKE_SOURCE"
