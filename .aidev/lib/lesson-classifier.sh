#!/bin/bash
# lesson-classifier.sh — Classificador de Scope de Lições Aprendidas
# Classifica lições como local, global (stack-específica) ou universal
#
# Uso:
#   source .aidev/lib/lesson-classifier.sh
#   classify_lesson ".aidev/memory/kb/2026-02-22-foo.md"
#   classify_all_lessons
#
# Dependências: lib/core.sh (print_*), grep

AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Keywords que indicam scope LOCAL (projeto-específico)
LOCAL_KEYWORDS="docker-compose\.yml|\.env|docker|Dockerfile|sail|container|deploy|vps|servidor|nginx|Apache|migration|\.aidev/|install_path|CLI_INSTALL_PATH"

# Keywords que indicam scope GLOBAL (stack-específico)
GLOBAL_KEYWORDS="Laravel|Livewire|Alpine|Blade|Eloquent|Inertia|Filament|PHP|Composer|artisan|React|Vue|Next\.js|Tailwind|Node\.js|npm|Vite|Python|Django|Flask|FastAPI"

# Keywords que indicam scope UNIVERSAL (qualquer projeto)
UNIVERSAL_KEYWORDS="TDD|YAGNI|DRY|git|commit|branch|merge|debug|refactor|test|CI/CD|pipeline|cache|performance|token|optimization|prompt|API|REST|HTTP|SOLID|clean code|design pattern"

# ============================================================================
# CLASSIFICAÇÃO
# ============================================================================

# Classifica o scope de uma lição com base no conteúdo
# Retorna: "local", "global" ou "universal"
classify_lesson_scope() {
    local file="$1"
    [ ! -f "$file" ] && echo "unknown" && return 1

    local content=$(cat "$file")
    local local_score=0
    local global_score=0
    local universal_score=0

    # Contar matches para cada categoria (grep -o + wc -l para contagem precisa)
    local_score=$(echo "$content" | grep -oiE "$LOCAL_KEYWORDS" 2>/dev/null | wc -l)
    global_score=$(echo "$content" | grep -oiE "$GLOBAL_KEYWORDS" 2>/dev/null | wc -l)
    universal_score=$(echo "$content" | grep -oiE "$UNIVERSAL_KEYWORDS" 2>/dev/null | wc -l)

    # Limpar whitespace do wc
    local_score=$((local_score + 0))
    global_score=$((global_score + 0))
    universal_score=$((universal_score + 0))

    # Se tem tags explícitas, usar como boost
    if echo "$content" | grep -qiE "tags:.*\b(docker|deploy|vps|install|servidor)\b"; then
        local_score=$((local_score + 5))
    fi
    if echo "$content" | grep -qiE "tags:.*\b(laravel|livewire|php|blade|eloquent)\b"; then
        global_score=$((global_score + 5))
    fi
    if echo "$content" | grep -qiE "tags:.*\b(tdd|dry|yagni|git|debug|optimization)\b"; then
        universal_score=$((universal_score + 5))
    fi

    # Decidir scope pelo maior score
    if [ "$universal_score" -ge "$global_score" ] && [ "$universal_score" -ge "$local_score" ] && [ "$universal_score" -gt 0 ]; then
        echo "universal"
    elif [ "$global_score" -ge "$local_score" ] && [ "$global_score" -gt 0 ]; then
        echo "global"
    elif [ "$local_score" -gt 0 ]; then
        echo "local"
    else
        echo "local"  # Default conservador
    fi
}

# Classifica e adiciona metadata ao frontmatter de uma lição
# Uso: classify_lesson "/path/to/lesson.md"
classify_lesson() {
    local file="$1"
    [ ! -f "$file" ] && { echo "Arquivo não encontrado: $file" >&2; return 1; }

    local scope=$(classify_lesson_scope "$file")
    local basename=$(basename "$file")

    # Verificar se já tem scope definido
    if grep -qE '^scope:' "$file" 2>/dev/null; then
        local existing_scope=$(grep -oE '^scope: (local|global|universal)' "$file" | awk '{print $2}')
        echo "  ℹ $basename: scope já definido ($existing_scope)"
        echo "$existing_scope"
        return 0
    fi

    # Verificar se tem frontmatter YAML (---...---)
    if head -1 "$file" | grep -q '^---$'; then
        # Inserir scope no frontmatter existente (após primeira ---)
        sed -i '1,/^---$/ { /^---$/a\scope: '"$scope"'
        }' "$file" 2>/dev/null

        # Corrigir: sed pode inserir após ambos os ---
        # Garantir que scope aparece apenas uma vez
        local count=$(grep -c '^scope:' "$file")
        if [ "$count" -gt 1 ]; then
            # Remover duplicados, manter o primeiro
            sed -i '0,/^scope:/! { /^scope:/d }' "$file"
        fi
    else
        # Sem frontmatter: criar
        local tmp=$(mktemp)
        echo "---" > "$tmp"
        echo "scope: $scope" >> "$tmp"
        echo "---" >> "$tmp"
        echo "" >> "$tmp"
        cat "$file" >> "$tmp"
        mv "$tmp" "$file"
    fi

    echo "  ✓ $basename: classificado como $scope"
    echo "$scope"
}

# Classifica todas as lições no KB
# Uso: classify_all_lessons
classify_all_lessons() {
    local kb_dir="$AIDEV_ROOT/memory/kb"
    [ ! -d "$kb_dir" ] && { echo "Diretório KB não encontrado"; return 1; }

    local total=0
    local local_count=0
    local global_count=0
    local universal_count=0

    echo "=== Classificação de Lições ==="
    for file in "$kb_dir"/*.md; do
        [ ! -f "$file" ] && continue
        ((total++))

        local scope=$(classify_lesson "$file" | tail -1)
        case "$scope" in
            local) ((local_count++)) ;;
            global) ((global_count++)) ;;
            universal) ((universal_count++)) ;;
        esac
    done

    echo ""
    echo "=== Resumo ==="
    echo "Total: $total | Local: $local_count | Global: $global_count | Universal: $universal_count"
}
