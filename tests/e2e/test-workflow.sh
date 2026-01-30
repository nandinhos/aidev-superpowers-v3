#!/bin/bash

# ============================================================================
# Testes E2E - Workflow Completo
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/lib/loader.sh"
load_all_modules

# ============================================================================
# Setup
# ============================================================================

E2E_PROJECT="/tmp/aidev-e2e-test"
AIDEV="$ROOT_DIR/bin/aidev"

cleanup() {
    rm -rf "$E2E_PROJECT"
}

setup() {
    cleanup
    mkdir -p "$E2E_PROJECT"
}

# ============================================================================
# E2E: Novo Projeto do Zero
# ============================================================================

test_section "E2E - Novo Projeto do Zero"

setup

# 1. Inicializa projeto
output=$("$AIDEV" init --install-in "$E2E_PROJECT" 2>&1)
assert_contains "$output" "instalado com sucesso" "Init retorna sucesso"

# 2. Verifica status
output=$("$AIDEV" status --install-in "$E2E_PROJECT" 2>&1)
assert_contains "$output" "8 agentes" "Status conta 8 agentes"
assert_contains "$output" "4 skills" "Status conta 4 skills"

# 3. Adiciona customizações
"$AIDEV" add-skill custom-workflow --install-in "$E2E_PROJECT" > /dev/null 2>&1
"$AIDEV" add-agent reviewer --install-in "$E2E_PROJECT" > /dev/null 2>&1

# 4. Verifica que customizações existem
output=$("$AIDEV" status --install-in "$E2E_PROJECT" 2>&1)
assert_contains "$output" "custom-workflow" "Custom skill aparece no status"
assert_contains "$output" "reviewer" "Custom agent aparece no status"

# 5. Doctor deve passar
output=$("$AIDEV" doctor --install-in "$E2E_PROJECT" 2>&1)
assert_contains "$output" "Tudo OK" "Doctor passa sem problemas"

# ============================================================================
# E2E: Upgrade de Instalação
# ============================================================================

test_section "E2E - Upgrade de Instalação"

# Modifica um arquivo de agente para simular versão antiga
echo "# Versão antiga" > "$E2E_PROJECT/.aidev/agents/orchestrator.md"

# Executa upgrade
output=$("$AIDEV" upgrade --install-in "$E2E_PROJECT" 2>&1)
assert_contains "$output" "Atualização concluída" "Upgrade completa"
assert_contains "$output" "Backup salvo" "Backup criado"

# Verifica que arquivo foi atualizado
content=$(cat "$E2E_PROJECT/.aidev/agents/orchestrator.md")
assert_contains "$content" "Orchestrator" "Orchestrator restaurado"

# ============================================================================
# E2E: Dry Run
# ============================================================================

test_section "E2E - Modo Dry Run"

DRY_PROJECT="/tmp/aidev-dry-run-test"
rm -rf "$DRY_PROJECT"
mkdir -p "$DRY_PROJECT"

# Executa com dry-run
output=$("$AIDEV" init --dry-run --install-in "$DRY_PROJECT" 2>&1)

# Verifica que mostra o que seria feito
assert_contains "$output" "DRY-RUN" "Modo dry-run ativado"
assert_contains "$output" "Criaria diretório" "Mostra diretórios"
assert_contains "$output" "Criaria arquivo" "Mostra arquivos"

# Verifica que NÃO criou nada
test ! -d "$DRY_PROJECT/.aidev" && result="ok" || result="fail"
assert_equals "$result" "ok" "Dry run não cria arquivos"

rm -rf "$DRY_PROJECT"

# ============================================================================
# E2E: Detecção Multi-Stack
# ============================================================================

test_section "E2E - Detecção de Stacks"

# Testa Laravel
LARAVEL_PROJECT="/tmp/aidev-laravel-e2e"
rm -rf "$LARAVEL_PROJECT"
mkdir -p "$LARAVEL_PROJECT"
echo '{"require": {"laravel/framework": "^10.0"}}' > "$LARAVEL_PROJECT/composer.json"

output=$("$AIDEV" init --install-in "$LARAVEL_PROJECT" 2>&1)
assert_contains "$output" "Stack detectada: laravel" "Detecta Laravel"
assert_file_exists "$LARAVEL_PROJECT/.aidev/rules/laravel.md" "Rule Laravel instalada"

rm -rf "$LARAVEL_PROJECT"

# Testa Node/Express
NODE_PROJECT="/tmp/aidev-node-e2e"
rm -rf "$NODE_PROJECT"
mkdir -p "$NODE_PROJECT"
echo '{"dependencies": {"express": "^4.0"}}' > "$NODE_PROJECT/package.json"

output=$("$AIDEV" init --install-in "$NODE_PROJECT" 2>&1)
assert_contains "$output" "Stack detectada: express" "Detecta Express"
assert_file_exists "$NODE_PROJECT/.aidev/rules/generic.md" "Rule genérica instalada"

rm -rf "$NODE_PROJECT"

# Cleanup final
cleanup
