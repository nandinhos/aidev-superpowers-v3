#!/bin/bash
# lesson-curator.sh — Curadoria de Lições com suporte a MCPs
# Valida lições antes de promovê-las a regras
#
# Uso:
#   source .aidev/lib/lesson-curator.sh
#   curate_lesson ".aidev/memory/kb/2026-02-22-foo.md"
#   curate_eligible_lessons
#
# Dependências: lesson-classifier.sh, lesson-promoter.sh

AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Carregar dependências
[ -z "$(type -t classify_lesson_scope 2>/dev/null)" ] && \
    source "$AIDEV_ROOT/lib/lesson-classifier.sh" 2>/dev/null || true
[ -z "$(type -t promote_lesson 2>/dev/null)" ] && \
    source "$AIDEV_ROOT/lib/lesson-promoter.sh" 2>/dev/null || true

# ============================================================================
# CURADORIA
# ============================================================================

# Verifica se lição já passou por curadoria
is_curated() {
    local file="$1"
    grep -q '^curated:' "$file" 2>/dev/null
}

# Marca lição com resultado de curadoria
mark_curated() {
    local file="$1"
    local result="$2"  # approved, rejected, adjust
    local note="${3:-}"

    if grep -q '^curated:' "$file" 2>/dev/null; then
        sed -i "s/^curated:.*/curated: $result/" "$file"
    elif head -1 "$file" | grep -q '^---$'; then
        sed -i "0,/^---$/! { 0,/^---$/s/^---$/curated: $result\ncurated_at: $(date +%Y-%m-%d)\n---/ }" "$file" 2>/dev/null || true
    fi
}

# Curadoria básica — verifica qualidade da lição
# Em ambientes com MCP ativo, delegaria para Context7/Laravel Boost
# Aqui implementa validação heurística como fallback
curate_lesson() {
    local file="$1"
    [ ! -f "$file" ] && { echo "  ✗ Arquivo não encontrado: $file" >&2; return 1; }

    local basename=$(basename "$file")
    local scope=$(classify_lesson_scope "$file")

    # Só curadoria para global/universal
    if [ "$scope" = "local" ]; then
        echo "  ⊘ $basename: scope local — curadoria não necessária"
        return 1
    fi

    # Já curada?
    if is_curated "$file"; then
        local existing=$(grep '^curated:' "$file" | awk '{print $2}')
        echo "  ℹ $basename: já curada ($existing)"
        return 0
    fi

    local content=$(cat "$file")
    local issues=0
    local warnings=0

    echo "  📋 Curando: $basename (scope: $scope)"

    # Validação 1: Tem solução?
    if ! echo "$content" | grep -qiE '^#+.*Solução|^#+.*Solution'; then
        echo "    ✗ Sem seção Solução"
        ((issues++))
    fi

    # Validação 2: Solução tem conteúdo substancial (>20 chars)?
    local solucao=$(echo "$content" | awk '/^#+.*[Ss]olu[çc][ãa]o/{found=1;next} /^#/{if(found)exit} found' | tr -d '[:space:]')
    if [ ${#solucao} -lt 20 ]; then
        echo "    ⚠ Solução muito curta (${#solucao} chars)"
        ((warnings++))
    fi

    # Validação 3: Tem exemplo ou código?
    if echo "$content" | grep -qE '```|`[^`]+`'; then
        echo "    ✓ Contém exemplos de código"
    else
        echo "    ⚠ Sem exemplos de código (recomendado)"
        ((warnings++))
    fi

    # Validação 4: Referência a commit/versão?
    if echo "$content" | grep -qiE 'commit|versão|version|v[0-9]'; then
        echo "    ✓ Tem referência de versão/commit"
    fi

    # Decisão
    if [ $issues -gt 0 ]; then
        echo "    ➤ Resultado: AJUSTAR ($issues problemas, $warnings avisos)"
        mark_curated "$file" "adjust"
        return 1
    elif [ $warnings -gt 1 ]; then
        echo "    ➤ Resultado: APROVADA COM RESSALVAS ($warnings avisos)"
        mark_curated "$file" "approved"
        return 0
    else
        echo "    ➤ Resultado: APROVADA"
        mark_curated "$file" "approved"
        return 0
    fi
}

# Curadoria + promoção automática para lições elegíveis
curate_and_promote() {
    local kb_dir="$AIDEV_ROOT/memory/kb"
    [ ! -d "$kb_dir" ] && { echo "Diretório KB não encontrado"; return 1; }

    local total=0
    local curated=0
    local promoted=0

    echo "=== Curadoria e Promoção Automática ==="
    for file in "$kb_dir"/*.md; do
        [ ! -f "$file" ] && continue
        ((total++))

        if curate_lesson "$file" 2>/dev/null; then
            ((curated++))
            if promote_lesson "$file" 2>/dev/null; then
                ((promoted++))
            fi
        fi
    done

    echo ""
    echo "=== Resumo ==="
    echo "Total: $total | Curadas: $curated | Promovidas: $promoted"
}

# ============================================================================
# DASHBOARD
# ============================================================================

# Dashboard de métricas do sistema de lições
lesson_dashboard() {
    local kb_dir="$AIDEV_ROOT/memory/kb"
    local rules_dir="$AIDEV_ROOT/rules"

    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║           Dashboard de Lições Aprendidas               ║"
    echo "╚══════════════════════════════════════════════════════════╝"

    # Contagem por scope
    local total=0
    local local_count=0
    local global_count=0
    local universal_count=0
    local curated_count=0
    local promoted_count=0

    if [ -d "$kb_dir" ]; then
        for file in "$kb_dir"/*.md; do
            [ ! -f "$file" ] && continue
            ((total++))

            local scope=$(classify_lesson_scope "$file" 2>/dev/null)
            case "$scope" in
                local) ((local_count++)) ;;
                global) ((global_count++)) ;;
                universal) ((universal_count++)) ;;
            esac

            if is_curated "$file" 2>/dev/null; then
                ((curated_count++))
            fi
        done
    fi

    # Contar regras existentes
    local rules_count=0
    if [ -d "$rules_dir" ]; then
        rules_count=$(grep -c '^## Regra:' "$rules_dir"/*.md 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')
    fi

    echo ""
    echo "  📚 Lições no KB:     $total"
    echo "  ├─ Local:            $local_count"
    echo "  ├─ Global:           $global_count"
    echo "  └─ Universal:        $universal_count"
    echo ""
    echo "  ✅ Curadas:           $curated_count"
    echo "  📏 Regras geradas:   $rules_count"
    echo ""

    # Taxa de curadoria
    if [ $total -gt 0 ]; then
        local rate=$((curated_count * 100 / total))
        echo "  📊 Taxa de curadoria: $rate%"
    fi
    echo ""
}
