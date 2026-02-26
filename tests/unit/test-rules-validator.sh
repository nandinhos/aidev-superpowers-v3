#!/bin/bash

# ============================================================================
# Testes Unitários - rules-validator.sh (Sprint 2 — TDD RED PHASE)
# Rules Engine - Enforcement: Validação pós-ação
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

source "$ROOT_DIR/tests/helpers/test-framework.sh"
type test_section &>/dev/null || test_section() { echo ""; echo "--- $* ---"; }

VALIDATOR="$ROOT_DIR/.aidev/engine/rules-validator.sh"

# ============================================================================
# SETUP
# ============================================================================
setup() {
    source "$VALIDATOR" 2>/dev/null || { echo "❌ SETUP: rules-validator.sh não encontrado"; exit 1; }
}

# ============================================================================
# validate_commit_format
# ============================================================================
test_section "validate_commit_format"

setup

# Commits válidos
assert_equals "pass" "$(validate_commit_format "feat(auth): adiciona autenticação jwt")" \
    "feat em português — pass"

assert_equals "pass" "$(validate_commit_format "fix(api): corrige validacao de email")" \
    "fix em português — pass"

assert_equals "pass" "$(validate_commit_format "chore(plans): conclui sprint 1")" \
    "chore com escopo — pass"

assert_equals "pass" "$(validate_commit_format "refactor(utils): extrai funcao de formatacao")" \
    "refactor válido — pass"

# Commits inválidos — emojis
assert_equals "error" "$(validate_commit_format "feat(auth): ✨ adiciona autenticacao")" \
    "emoji no commit — error"

assert_equals "error" "$(validate_commit_format "feat: :sparkles: add feature")" \
    "emoji shortcode — error"

# Commits inválidos — inglês
assert_equals "error" "$(validate_commit_format "feat(auth): add authentication")" \
    "mensagem em inglês — error"

assert_equals "error" "$(validate_commit_format "fix: fix the bug")" \
    "fix em inglês — error"

# Commits inválidos — co-autoria
assert_equals "error" "$(validate_commit_format "feat(x): algo

Co-Authored-By: Claude <noreply@anthropic.com>")" \
    "co-autoria proibida — error"

# Commits inválidos — tipo errado
assert_equals "error" "$(validate_commit_format "update(auth): altera login")" \
    "tipo não permitido — error"

# Commits inválidos — sem escopo (apenas warning)
assert_equals "warning" "$(validate_commit_format "feat: adiciona funcionalidade")" \
    "sem escopo — warning"

# ============================================================================
# validate_file_count
# ============================================================================
test_section "validate_file_count"

# Cria lista de arquivos fictícios
FILES_OK=$(seq 1 9 | xargs -I{} echo "file{}.sh" | tr '\n' ' ')
FILES_LIMIT=$(seq 1 10 | xargs -I{} echo "file{}.sh" | tr '\n' ' ')
FILES_OVER=$(seq 1 15 | xargs -I{} echo "file{}.sh" | tr '\n' ' ')

assert_equals "pass" "$(validate_file_count 9)" \
    "9 arquivos — pass (abaixo do limite 10)"

assert_equals "warning" "$(validate_file_count 10)" \
    "10 arquivos — warning (no limite)"

assert_equals "error" "$(validate_file_count 15)" \
    "15 arquivos — error (acima do limite)"

# ============================================================================
# validate_protected_path
# ============================================================================
test_section "validate_protected_path"

assert_equals "pass" "$(validate_protected_path "src/auth/login.sh")" \
    "caminho normal — pass"

assert_equals "pass" "$(validate_protected_path ".aidev/rules/generic.md")" \
    "editar regras — pass (permitido)"

assert_equals "error" "$(validate_protected_path ".aidev/state/unified.json")" \
    "editar state/ — error (protegido)"

assert_equals "error" "$(validate_protected_path ".aidev/state/checkpoint.md")" \
    "editar checkpoint diretamente — error"

assert_equals "warning" "$(validate_protected_path ".aidev/agents/orchestrator.md")" \
    "editar agente core — warning"

# ============================================================================
# validate_no_manual_plan_move
# ============================================================================
test_section "validate_no_manual_plan_move"

# Simula staging area com um arquivo de plano
assert_equals "pass" "$(validate_no_manual_plan_move "src/app.sh")" \
    "arquivo de código — pass"

assert_equals "error" "$(validate_no_manual_plan_move ".aidev/plans/backlog/feature.md" "current")" \
    "arquivo de plano em trânsito manual — error"

# ============================================================================
# RESULTADO FINAL
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Resultado: $TESTS_PASSED passou(aram) | $TESTS_FAILED falhou(aram)"
[ "$TESTS_FAILED" -eq 0 ] && echo "✅ Todos os testes passaram" || echo "❌ Testes com falha"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit "$TESTS_FAILED"
