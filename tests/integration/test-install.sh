#!/bin/bash

# ============================================================================
# Testes de Integração - Fluxo Completo de Instalação
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_all_modules

# ============================================================================
# Setup
# ============================================================================

TEST_PROJECT_DIR="/tmp/aidev-integration-test"

cleanup() {
    rm -rf "$TEST_PROJECT_DIR"
}

setup() {
    cleanup
    mkdir -p "$TEST_PROJECT_DIR"
}

# ============================================================================
# Testes
# ============================================================================

test_section "Integração - Instalação Completa"

setup

# Executa aidev init
"$ROOT_DIR/bin/aidev" init --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1

# Verifica estrutura criada
assert_dir_exists "$TEST_PROJECT_DIR/.aidev" ".aidev/ criado"
assert_dir_exists "$TEST_PROJECT_DIR/.aidev/agents" "agents/ criado"
assert_dir_exists "$TEST_PROJECT_DIR/.aidev/skills" "skills/ criado"
assert_dir_exists "$TEST_PROJECT_DIR/.aidev/rules" "rules/ criado"
assert_dir_exists "$TEST_PROJECT_DIR/.aidev/state" "state/ criado"

test_section "Integração - Agentes Instalados"

# Verifica agentes
for agent in orchestrator architect backend frontend qa devops legacy-analyzer security-guardian; do
    assert_file_exists "$TEST_PROJECT_DIR/.aidev/agents/${agent}.md" "Agent $agent instalado"
done

test_section "Integração - Skills Instaladas"

# Verifica skills
for skill in brainstorming writing-plans test-driven-development systematic-debugging; do
    assert_file_exists "$TEST_PROJECT_DIR/.aidev/skills/$skill/SKILL.md" "Skill $skill instalada"
done

test_section "Integração - Rules Instaladas"

# Verifica rules
assert_file_exists "$TEST_PROJECT_DIR/.aidev/rules/generic.md" "Rule generic instalada"

test_section "Integração - MCP Configurado"

# Verifica MCP
assert_file_exists "$TEST_PROJECT_DIR/.mcp.json" ".mcp.json criado"
assert_contains "$(cat "$TEST_PROJECT_DIR/.mcp.json")" "context7" "MCP contém context7"

test_section "Integração - Status Command"

# Testa comando status
status_output=$("$ROOT_DIR/bin/aidev" status --install-in "$TEST_PROJECT_DIR" 2>&1)
assert_contains "$status_output" "AI Dev instalado" "Status detecta instalação"
assert_contains "$status_output" "orchestrator" "Status lista orchestrator"

test_section "Integração - Doctor Command"

# Testa comando doctor
doctor_output=$("$ROOT_DIR/bin/aidev" doctor --install-in "$TEST_PROJECT_DIR" 2>&1)
assert_contains "$doctor_output" ".aidev/ existe" "Doctor verifica .aidev"

test_section "Integração - Add Commands"

# Testa add-skill
"$ROOT_DIR/bin/aidev" add-skill test-skill --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1
assert_file_exists "$TEST_PROJECT_DIR/.aidev/skills/test-skill/SKILL.md" "add-skill cria skill"

# Testa add-agent
"$ROOT_DIR/bin/aidev" add-agent test-agent --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1
assert_file_exists "$TEST_PROJECT_DIR/.aidev/agents/test-agent.md" "add-agent cria agent"

# Testa add-rule
"$ROOT_DIR/bin/aidev" add-rule test-rule --install-in "$TEST_PROJECT_DIR" > /dev/null 2>&1
assert_file_exists "$TEST_PROJECT_DIR/.aidev/rules/test-rule.md" "add-rule cria rule"

# Cleanup before security tests
cleanup

# ============================================================================
# Testes de Segurança - Validação de Paths no Uninstall
# ============================================================================

test_section "Segurança - Validação de Paths no Uninstall"

# Testa validação de path vazio
export AIDEV_INSTALL_DIR=""
bash "$ROOT_DIR/uninstall.sh" <<< "y" > /tmp/uninstall-empty.log 2>&1 && result="success" || result="error"
assert_equals "$result" "error" "Rejeita INSTALL_DIR vazio"
assert_contains "$(cat /tmp/uninstall-empty.log)" "vazio" "Mensagem de erro para path vazio"

# Testa validação de path /
export AIDEV_INSTALL_DIR="/"
bash "$ROOT_DIR/uninstall.sh" <<< "y" > /tmp/uninstall-root.log 2>&1 && result="success" || result="error"
assert_equals "$result" "error" "Rejeita path /"
assert_contains "$(cat /tmp/uninstall-root.log)" "raiz" "Mensagem de erro para path raiz"

# Testa validação de paths do sistema
for path in "/usr" "/bin" "/etc" "/home" "/var"; do
    export AIDEV_INSTALL_DIR="$path"
    bash "$ROOT_DIR/uninstall.sh" <<< "y" > /tmp/uninstall-system.log 2>&1 && result="success" || result="error"
    assert_equals "$result" "error" "Rejeita path do sistema: $path"
done

test_section "Segurança - Modo Dry-Run"

# Cria diretório para teste de dry-run
TEST_UNINSTALL_DIR="/tmp/aidev-uninstall-test"
mkdir -p "$TEST_UNINSTALL_DIR/.aidev"
touch "$TEST_UNINSTALL_DIR/.aidev/test.txt"
export AIDEV_INSTALL_DIR="$TEST_UNINSTALL_DIR"

# Testa modo dry-run (não deve deletar)
AIDEV_DRY_RUN=1 bash "$ROOT_DIR/uninstall.sh" <<< "y" > /tmp/uninstall-dryrun.log 2>&1 || true
assert_dir_exists "$TEST_UNINSTALL_DIR" "Dry-run não deleta diretório"
assert_contains "$(cat /tmp/uninstall-dryrun.log)" "dry-run" "Mensagem de dry-run presente"

# Testa uninstall normal em path seguro
unset AIDEV_DRY_RUN
bash "$ROOT_DIR/uninstall.sh" <<< "y" > /tmp/uninstall-safe.log 2>&1 || true
if [[ -d "$TEST_UNINSTALL_DIR" ]]; then
    assert_equals "false" "true" "Uninstall normal deve deletar"
else
    assert_equals "true" "true" "Uninstall normal deletou com sucesso"
fi

# Cleanup final
rm -f /tmp/uninstall-*.log
rm -rf "$TEST_UNINSTALL_DIR"
unset AIDEV_INSTALL_DIR
