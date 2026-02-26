#!/usr/bin/env bash
# install-hooks.sh — Instala hooks do git para enforcement do Rules Engine
# Uso: bash .aidev/engine/install-hooks.sh [project_root]

set -euo pipefail

PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
AIDEV_ENGINE="$PROJECT_ROOT/.aidev/engine"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "✗ Diretório .git/hooks não encontrado em $PROJECT_ROOT" >&2
    exit 1
fi

# ============================================================================
# commit-msg hook — valida formato do commit
# ============================================================================
cat > "$HOOKS_DIR/commit-msg" <<'HOOK_EOF'
#!/usr/bin/env bash
# commit-msg hook — Rules Engine: validate_commit_format
# Instalado por: .aidev/engine/install-hooks.sh

COMMIT_MSG_FILE="$1"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
VALIDATOR="$REPO_ROOT/.aidev/engine/rules-validator.sh"

# Ignora se validator não existe (não bloqueia worflow)
[ -f "$VALIDATOR" ] || exit 0

# Carrega validator
source "$VALIDATOR" 2>/dev/null || exit 0

# Executa validação
run_pre_commit_check "$COMMIT_MSG_FILE"
HOOK_EOF

chmod +x "$HOOKS_DIR/commit-msg"
echo "✓ Hook commit-msg instalado: $HOOKS_DIR/commit-msg"

# ============================================================================
# pre-commit hook — valida dedup de arquivos de regras
# ============================================================================
cat > "$HOOKS_DIR/pre-commit" <<'HOOK_EOF'
#!/usr/bin/env bash
# pre-commit hook — Rules Engine: rules_dedup_check em arquivos staged
# Instalado por: .aidev/engine/install-hooks.sh

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DEDUP="$REPO_ROOT/.aidev/engine/rules-dedup.sh"

[ -f "$DEDUP" ] || exit 0
source "$DEDUP" 2>/dev/null || exit 0

# Verifica arquivos .md staged
staged_md=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "\.md$" || true)

violations=0
for file in $staged_md; do
    result=$(rules_dedup_check "$file")
    if [ "$result" = "violation" ]; then
        rules_dedup_alert "$file" >&2
        violations=$((violations + 1))
    fi
done

[ "$violations" -eq 0 ] && exit 0

echo "✗ pre-commit bloqueado: $violations arquivo(s) de regras em local não-canônico" >&2
echo "  Mova para .aidev/rules/ ou use 'git commit --no-verify' para forçar" >&2
exit 1
HOOK_EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ Hook pre-commit instalado: $HOOKS_DIR/pre-commit"

echo ""
echo "Rules Engine hooks instalados com sucesso."
echo "  commit-msg → valida formato do commit (idioma, emojis, co-autoria)"
echo "  pre-commit → detecta arquivos de regras em locais não-canônicos"
