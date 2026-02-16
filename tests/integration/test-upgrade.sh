#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Upgrade Integration Tests
# ============================================================================
# Testes de integracao para cmd_upgrade: backup, customizacao, dry-run, rules
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_all_modules

# ============================================================================
# Setup / Teardown
# ============================================================================

TEST_PROJECT_DIR=""

setup() {
    TEST_PROJECT_DIR=$(mktemp -d)
    # Inicializa projeto de teste
    AIDEV_INTERACTIVE=false CLI_LANGUAGE_SET=true CLI_LANGUAGE="pt-BR" \
        "$ROOT_DIR/bin/aidev" init --install-in "$TEST_PROJECT_DIR" --stack generic > /dev/null 2>&1
}

cleanup() {
    if [ -d "$TEST_PROJECT_DIR" ]; then
        rm -rf "$TEST_PROJECT_DIR"
    fi
}

trap cleanup EXIT

# ============================================================================
# Tests: Backup criado durante upgrade
# ============================================================================

test_section "Integracao - Upgrade cria backup"

setup

# Executa upgrade
"$ROOT_DIR/bin/aidev" upgrade --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1

# Verifica backup
backup_exists="false"
if ls "$TEST_PROJECT_DIR/.aidev/backups/"* >/dev/null 2>&1; then
    backup_exists="true"
fi
assert_equals "true" "$backup_exists" "backup criado durante upgrade"

cleanup

# ============================================================================
# Tests: Arquivo customizado preservado
# ============================================================================

test_section "Integracao - Upgrade preserva customizacoes"

setup

# Customiza um agent
if [ -f "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md" ]; then
    echo "# CUSTOM CONTENT" >> "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md"
    custom_before=$(tail -1 "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md")
fi

# Executa upgrade SEM --force
"$ROOT_DIR/bin/aidev" upgrade --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1

# Verifica que customizacao foi preservada (should_write_file protege)
if [ -f "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md" ]; then
    custom_after=$(tail -1 "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md")
    assert_equals "$custom_before" "$custom_after" "orchestrator.md customizado preservado"
else
    assert_equals "0" "1" "orchestrator.md existe apos upgrade"
fi

cleanup

# ============================================================================
# Tests: Rules reinstaladas
# ============================================================================

test_section "Integracao - Upgrade reinstala rules"

setup

# Remove rules para simular estado antigo
rm -f "$TEST_PROJECT_DIR/.aidev/rules/generic.md" 2>/dev/null

# Executa upgrade
"$ROOT_DIR/bin/aidev" upgrade --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1

# Verifica que rules foram reinstaladas
if [ -f "$TEST_PROJECT_DIR/.aidev/rules/generic.md" ]; then
    assert_equals "0" "0" "generic.md reinstalado pelo upgrade"
else
    assert_equals "0" "1" "generic.md reinstalado pelo upgrade"
fi

cleanup

# ============================================================================
# Tests: Dry-run nao modifica nada
# ============================================================================

test_section "Integracao - Upgrade dry-run"

setup

# Pega checksum antes
checksum_before=""
if [ -f "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md" ]; then
    checksum_before=$(sha256sum "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md" 2>/dev/null | cut -d' ' -f1)
fi

# Executa upgrade com dry-run
AIDEV_DRY_RUN=true "$ROOT_DIR/bin/aidev" upgrade --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1

# Verifica que nada mudou
checksum_after=""
if [ -f "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md" ]; then
    checksum_after=$(sha256sum "$TEST_PROJECT_DIR/.aidev/agents/orchestrator.md" 2>/dev/null | cut -d' ' -f1)
fi

if [ -n "$checksum_before" ] && [ -n "$checksum_after" ]; then
    assert_equals "$checksum_before" "$checksum_after" "dry-run nao modifica arquivos"
else
    assert_equals "0" "0" "dry-run nao modifica arquivos (skip - sem checksum)"
fi

cleanup

# ============================================================================
# Tests: LLM limits instalado no upgrade
# ============================================================================

test_section "Integracao - Upgrade instala llm-limits"

setup

# Remove llm-limits para simular estado antigo
rm -f "$TEST_PROJECT_DIR/.aidev/rules/llm-limits.md" 2>/dev/null

# Executa upgrade
"$ROOT_DIR/bin/aidev" upgrade --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1

# Verifica que llm-limits foi instalado
if [ -f "$TEST_PROJECT_DIR/.aidev/rules/llm-limits.md" ]; then
    assert_equals "0" "0" "llm-limits.md instalado pelo upgrade"
else
    assert_equals "0" "1" "llm-limits.md instalado pelo upgrade"
fi

cleanup
