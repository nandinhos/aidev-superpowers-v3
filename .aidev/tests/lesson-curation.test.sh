#!/bin/bash
# lesson-curation.test.sh — Testes do curador e dashboard de lições
#
# Uso: bash .aidev/tests/lesson-curation.test.sh

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
    TMP_DIR=$(mktemp -d)
    export AIDEV_ROOT="$TMP_DIR"
    mkdir -p "$TMP_DIR/memory/kb" "$TMP_DIR/rules" "$TMP_DIR/lib"

    # Copiar libs
    cp "$PROJECT_ROOT/.aidev/lib/lesson-classifier.sh" "$TMP_DIR/lib/" 2>/dev/null
    cp "$PROJECT_ROOT/.aidev/lib/lesson-promoter.sh" "$TMP_DIR/lib/" 2>/dev/null
    cp "$PROJECT_ROOT/.aidev/lib/lesson-curator.sh" "$TMP_DIR/lib/" 2>/dev/null

    # Mocks de print
    print_info() { echo "[INFO] $*"; }
    print_error() { echo "[ERROR] $*"; }
    print_warning() { echo "[WARN] $*"; }
    print_debug() { :; }
    print_section() { echo "--- $* ---"; }
    export -f print_info print_error print_warning print_debug print_section

    # Source dos módulos
    source "$TMP_DIR/lib/lesson-classifier.sh" 2>/dev/null || true
    source "$TMP_DIR/lib/lesson-promoter.sh" 2>/dev/null || true
    source "$TMP_DIR/lib/lesson-curator.sh" 2>/dev/null || true
}

cleanup() { rm -rf "$TMP_DIR" 2>/dev/null; }

# ============================================================================
# Cenário 1: Curadoria aprova lição bem-estruturada
# ============================================================================

test_curate_good_lesson() {
    echo ""
    echo "=== Cenário 1: Curadoria de lição completa ==="

    cat > "$TMP_DIR/memory/kb/2026-01-01-good-lesson.md" <<'EOF'
# Lição: Uso Correto de Livewire com Alpine

## Contexto
Projeto Laravel com Livewire e Alpine.js.

## Problema
Componentes não re-renderizam corretamente em loops.

## Solução
Usar `wire:key` com hash único: `wire:key="item-{{ $item->id }}-{{ md5(json_encode($item)) }}"`.

## Prevenção
Sempre usar wire:key em @foreach com Livewire.

Tags: laravel, livewire, alpine, blade
EOF

    local output=$(curate_lesson "$TMP_DIR/memory/kb/2026-01-01-good-lesson.md" 2>/dev/null)

    if echo "$output" | grep -qi "APROVADA"; then
        pass "Lição completa aprovada pela curadoria"
    else
        fail "Lição deveria ser aprovada" "Output: $output"
    fi
}

# ============================================================================
# Cenário 2: Curadoria rejeita lição sem solução
# ============================================================================

test_curate_bad_lesson() {
    echo ""
    echo "=== Cenário 2: Curadoria de lição incompleta ==="

    cat > "$TMP_DIR/memory/kb/2026-01-01-bad-lesson.md" <<'EOF'
# Lição: Problema com Livewire

## Contexto
Projeto Laravel.

## Problema
Algo não funciona com Livewire.

Tags: laravel, livewire
EOF

    local output=$(curate_lesson "$TMP_DIR/memory/kb/2026-01-01-bad-lesson.md" 2>/dev/null)

    if echo "$output" | grep -qi "AJUSTAR"; then
        pass "Lição sem Solução marcada para ajuste"
    else
        fail "Deveria marcar para ajuste" "Output: $output"
    fi
}

# ============================================================================
# Cenário 3: Lição LOCAL não passa por curadoria
# ============================================================================

test_curate_local_skip() {
    echo ""
    echo "=== Cenário 3: Lição LOCAL ignorada pela curadoria ==="

    cat > "$TMP_DIR/memory/kb/2026-01-01-local-lesson.md" <<'EOF'
# Lição: Config Docker no VPS

## Contexto
Configuração do docker-compose.yml no servidor de deploy.

## Problema
Container Docker com .env faltando no servidor deploy.

## Solução
Copiar .env do Docker para o servidor antes do deploy.

## Prevenção
Script de deploy verifica .env do container Docker.

Tags: docker, deploy, vps, servidor, container
EOF

    local output=$(curate_lesson "$TMP_DIR/memory/kb/2026-01-01-local-lesson.md" 2>/dev/null)

    if echo "$output" | grep -qi "local\|não necessária"; then
        pass "Lição LOCAL ignorada corretamente"
    else
        fail "Deveria ignorar lição local" "Output: $output"
    fi
}

# ============================================================================
# Cenário 4: Dashboard mostra métricas
# ============================================================================

test_dashboard() {
    echo ""
    echo "=== Cenário 4: Dashboard de métricas ==="

    local output=$(lesson_dashboard 2>/dev/null)

    if echo "$output" | grep -qi "Dashboard\|Lições no KB"; then
        pass "Dashboard renderizou corretamente"
    else
        fail "Dashboard não renderizou" "Output: $output"
    fi

    if echo "$output" | grep -qE "[0-9]+"; then
        pass "Dashboard mostra métricas numéricas"
    else
        fail "Dashboard sem métricas"
    fi
}

# ============================================================================
# Cenário 5: Pipeline completo: classificar → curar → promover
# ============================================================================

test_full_pipeline() {
    echo ""
    echo "=== Cenário 5: Pipeline completo ==="

    cat > "$TMP_DIR/memory/kb/2026-01-01-pipeline-test.md" <<'EOF'
# Lição: TDD Pipeline com Git

## Contexto
Aplicando TDD com git commit atômico e refactor.

## Problema
Sem disciplina de TDD, bugs aparecem em produção.

## Solução
Ciclo `RED → GREEN → REFACTOR` com git commit a cada etapa verde.

## Prevenção
Sempre iniciar com test first no TDD.

Tags: tdd, git, refactor, debug, optimization
EOF

    # Classificar
    local scope=$(classify_lesson_scope "$TMP_DIR/memory/kb/2026-01-01-pipeline-test.md")
    if [ "$scope" = "universal" ] || [ "$scope" = "global" ]; then
        pass "Classificação: $scope (elegível)"
    else
        fail "Classificação incorreta: $scope"
        return
    fi

    # Curar
    curate_lesson "$TMP_DIR/memory/kb/2026-01-01-pipeline-test.md" > /dev/null 2>&1

    # Promover
    promote_lesson "$TMP_DIR/memory/kb/2026-01-01-pipeline-test.md" > /dev/null 2>&1

    # Verificar regra criada
    if ls "$TMP_DIR/rules/"*.md &>/dev/null; then
        local rule_file=$(ls "$TMP_DIR/rules/"*.md | head -1)
        if grep -q "TDD Pipeline" "$rule_file" 2>/dev/null; then
            pass "Pipeline completo: lição → classificação → curadoria → regra"
        else
            fail "Regra não contém dados da lição"
        fi
    else
        fail "Nenhuma regra gerada pelo pipeline"
    fi
}

# ============================================================================
# Execução
# ============================================================================

main() {
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  Testes — Curadoria + Dashboard de Lições              ║"
    echo "╚══════════════════════════════════════════════════════════╝"

    setup

    test_curate_good_lesson
    test_curate_bad_lesson
    test_curate_local_skip
    test_dashboard
    test_full_pipeline

    cleanup

    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  Resultado: $TESTS_PASSED/$TESTS_TOTAL passed | $TESTS_FAILED failed"
    echo "════════════════════════════════════════════════════════════"

    [ $TESTS_FAILED -gt 0 ] && exit 1
    exit 0
}

main "$@"
