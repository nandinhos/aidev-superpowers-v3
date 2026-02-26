#!/bin/bash
# lesson-classification.test.sh — Testes do classificador e promotor de lições
#
# Uso: bash .aidev/tests/lesson-classification.test.sh

set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TMP_DIR=""

pass() { ((TESTS_PASSED++)); ((TESTS_TOTAL++)); echo "  ✅ PASS: $1"; }
fail() { ((TESTS_FAILED++)); ((TESTS_TOTAL++)); echo "  ❌ FAIL: $1"; [ -n "${2:-}" ] && echo "       Detalhe: $2"; }

setup() {
    export AIDEV_ROOT="$PROJECT_ROOT/.aidev"
    
    # Mocks de print
    print_info() { echo "[INFO] $*"; }
    print_error() { echo "[ERROR] $*"; }
    print_warning() { echo "[WARN] $*"; }
    print_debug() { :; }
    print_section() { echo "--- $* ---"; }
    export -f print_info print_error print_warning print_debug print_section

    # Source dos módulos
    source "$PROJECT_ROOT/.aidev/lib/lesson-classifier.sh" 2>/dev/null || true
    source "$PROJECT_ROOT/.aidev/lib/lesson-promoter.sh" 2>/dev/null || true

    # Criar dir temporário para testes
    TMP_DIR=$(mktemp -d)
}

cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null
}

# ============================================================================
# Cenário 1: Classificação LOCAL
# ============================================================================

test_classify_local() {
    echo ""
    echo "=== Cenário 1: Classificação de lição LOCAL ==="

    local lesson="$TMP_DIR/2026-01-01-docker-config.md"
    cat > "$lesson" <<'EOF'
---
title: Configuração Docker para o projeto
tags: [docker, deploy, vps, servidor]
---

# Lição: Docker Compose no VPS

## Contexto
Configuração do docker-compose.yml no servidor de produção.

## Problema
Container não iniciava por causa do .env faltando.

## Solução
Criar .env no servidor com as variáveis corretas.

## Prevenção
Automatizar deploy com script que verifica .env.
EOF

    local scope=$(classify_lesson_scope "$lesson")
    if [ "$scope" = "local" ]; then
        pass "Lição sobre Docker/VPS/.env classificada como LOCAL"
    else
        fail "Lição deveria ser LOCAL mas foi: $scope"
    fi
}

# ============================================================================
# Cenário 2: Classificação GLOBAL
# ============================================================================

test_classify_global() {
    echo ""
    echo "=== Cenário 2: Classificação de lição GLOBAL ==="

    local lesson="$TMP_DIR/2026-01-01-livewire-morph.md"
    cat > "$lesson" <<'EOF'
# Lição: Conflito Livewire + Alpine Morph

## Contexto
Usando Laravel Livewire com Alpine.js em Blade templates.

## Problema
Elementos com x-data dentro de @foreach do Livewire não atualizavam.

## Solução
Usar wire:key com hash MD5 dos dados para forçar re-render do componente Livewire.

## Prevenção
Sempre usar wire:key único em loops do Blade com Livewire.

Tags: laravel, livewire, alpine, blade
EOF

    local scope=$(classify_lesson_scope "$lesson")
    if [ "$scope" = "global" ]; then
        pass "Lição sobre Livewire/Alpine/Blade classificada como GLOBAL"
    else
        fail "Lição deveria ser GLOBAL mas foi: $scope"
    fi
}

# ============================================================================
# Cenário 3: Classificação UNIVERSAL
# ============================================================================

test_classify_universal() {
    echo ""
    echo "=== Cenário 3: Classificação de lição UNIVERSAL ==="

    local lesson="$TMP_DIR/2026-01-01-tdd-patterns.md"
    cat > "$lesson" <<'EOF'
# Lição: Padrões TDD para Debugging

## Contexto
Aplicando TDD e práticas DRY para refatorar código com YAGNI em mente.

## Problema
Testes falhando por causa de design pobre — sem seguir princípios SOLID.

## Solução
Refactor com TDD: RED → GREEN → REFACTOR. Commit atômico por teste.

## Prevenção
Sempre iniciar com test first. Git commit a cada ciclo verde.

Tags: tdd, dry, yagni, git, debug, refactor, optimization
EOF

    local scope=$(classify_lesson_scope "$lesson")
    if [ "$scope" = "universal" ]; then
        pass "Lição sobre TDD/DRY/YAGNI classificada como UNIVERSAL"
    else
        fail "Lição deveria ser UNIVERSAL mas foi: $scope"
    fi
}

# ============================================================================
# Cenário 4: Adição de metadata ao frontmatter
# ============================================================================

test_add_metadata() {
    echo ""
    echo "=== Cenário 4: Adição de metadata scope ao frontmatter ==="

    local lesson="$TMP_DIR/2026-01-01-test-metadata.md"
    cat > "$lesson" <<'EOF'
---
title: Teste de metadata
tags: [git, debug, refactor]
---

# Lição: Teste

## Contexto
Teste de adição de TDD metadata com git e refactor.

## Problema
Sem classificação.

## Solução
Classificar automaticamente.

## Prevenção
Rodar classificador após salvar.
EOF

    classify_lesson "$lesson" > /dev/null 2>&1

    if grep -q '^scope:' "$lesson"; then
        local scope_value=$(grep '^scope:' "$lesson" | awk '{print $2}')
        pass "Metadata 'scope: $scope_value' adicionada ao frontmatter"
    else
        fail "Metadata scope não foi adicionada ao arquivo"
    fi
}

# ============================================================================
# Cenário 5: Promoção de lição GLOBAL a regra
# ============================================================================

test_promote_global() {
    echo ""
    echo "=== Cenário 5: Promoção de lição GLOBAL a regra ==="

    # Sobrescrever AIDEV_ROOT para usar dir temporário
    local original_root="$AIDEV_ROOT"
    export AIDEV_ROOT="$TMP_DIR"
    mkdir -p "$TMP_DIR/rules" "$TMP_DIR/memory/kb"

    local lesson="$TMP_DIR/memory/kb/2026-01-01-livewire-test.md"
    cat > "$lesson" <<'EOF'
# Lição: Livewire Loop Fix

## Contexto
Projeto Laravel com Livewire.

## Problema
Loops do Livewire em Blade conflitam com morph do Alpine.

## Solução
Usar wire:key com hash de dados único por item do loop.

## Prevenção
Sempre usar wire:key em @foreach com componentes Livewire.

Tags: laravel, livewire, blade
EOF

    promote_lesson "$lesson" 2>/dev/null
    local result=$?

    if [ -f "$TMP_DIR/rules/laravel.md" ]; then
        pass "Regra criada em rules/laravel.md"
    else
        fail "Regra não criada em rules/laravel.md"
    fi

    if grep -q "Livewire Loop Fix" "$TMP_DIR/rules/laravel.md" 2>/dev/null; then
        pass "Regra contém título da lição"
    else
        fail "Regra não contém título da lição"
    fi

    if grep -q "wire:key" "$TMP_DIR/rules/laravel.md" 2>/dev/null; then
        pass "Regra contém solução extraída"
    else
        fail "Regra não contém solução extraída"
    fi

    # Restaurar AIDEV_ROOT
    export AIDEV_ROOT="$original_root"
}

# ============================================================================
# Cenário 6: Lição LOCAL não é promovida
# ============================================================================

test_no_promote_local() {
    echo ""
    echo "=== Cenário 6: Lição LOCAL não é promovida ==="

    local original_root="$AIDEV_ROOT"
    export AIDEV_ROOT="$TMP_DIR"
    mkdir -p "$TMP_DIR/rules" "$TMP_DIR/memory/kb"

    local lesson="$TMP_DIR/memory/kb/2026-01-01-docker-local.md"
    cat > "$lesson" <<'EOF'
# Lição: Docker no VPS

## Contexto
Configuração do docker-compose.yml no servidor de deploy.

## Problema
Container com variável .env faltando no deploy do servidor.

## Solução
Copiar .env para o servidor antes do deploy do container Docker.

## Prevenção
Script de deploy verifica .env do container Docker.

Tags: docker, deploy, vps, servidor
EOF

    local output=$(promote_lesson "$lesson" 2>/dev/null)

    if echo "$output" | grep -q "não elegível"; then
        pass "Lição LOCAL corretamente rejeitada para promoção"
    else
        fail "Lição LOCAL deveria ser rejeitada" "Output: $output"
    fi

    export AIDEV_ROOT="$original_root"
}

# ============================================================================
# Cenário 7: Lição já promovida não duplica
# ============================================================================

test_no_duplicate() {
    echo ""
    echo "=== Cenário 7: Lição já promovida não duplica ==="

    local original_root="$AIDEV_ROOT"
    export AIDEV_ROOT="$TMP_DIR"
    mkdir -p "$TMP_DIR/rules" "$TMP_DIR/memory/kb"

    local lesson="$TMP_DIR/memory/kb/2026-01-01-universal-test.md"
    cat > "$lesson" <<'EOF'
# Lição: TDD Universal Test

## Problema
Sem TDD obrigatório.

## Solução
TDD RED GREEN REFACTOR obrigatório. Git commit atômico.

## Prevenção
Sempre test first com TDD.

Tags: tdd, git, debug, optimization
EOF

    # Promover duas vezes
    promote_lesson "$lesson" > /dev/null 2>&1
    local output=$(promote_lesson "$lesson" 2>/dev/null)

    if echo "$output" | grep -q "já promovida"; then
        pass "Lição já promovida detectada — sem duplicação"
    else
        fail "Deveria detectar duplicação" "Output: $output"
    fi

    export AIDEV_ROOT="$original_root"
}

# ============================================================================
# Execução
# ============================================================================

main() {
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  Testes — Classificador + Promotor de Lições           ║"
    echo "╚══════════════════════════════════════════════════════════╝"

    setup

    test_classify_local
    test_classify_global
    test_classify_universal
    test_add_metadata
    test_promote_global
    test_no_promote_local
    test_no_duplicate

    cleanup

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Resultado: $TESTS_PASSED/$TESTS_TOTAL passed | $TESTS_FAILED failed"
    echo "════════════════════════════════════════════════════════════"

    [ $TESTS_FAILED -gt 0 ] && exit 1
    exit 0
}

main "$@"
