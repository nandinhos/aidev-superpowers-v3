#!/bin/bash
# lesson-promoter.sh — Promoção de Lição Validada a Regra
# Converte lições classificadas como global/universal em regras oficiais
#
# Uso:
#   source .aidev/lib/lesson-promoter.sh
#   promote_lesson ".aidev/memory/kb/2026-02-22-foo.md"
#   promote_eligible_lessons
#
# Dependências: lesson-classifier.sh, grep, sed

AIDEV_ROOT="${AIDEV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Carregar classificador se não estiver carregado
[ -z "$(type -t classify_lesson_scope 2>/dev/null)" ] && \
    source "$AIDEV_ROOT/lib/lesson-classifier.sh" 2>/dev/null || true

# ============================================================================
# PROMOÇÃO
# ============================================================================

# Extrai um slug limpo do nome do arquivo de lição
# Uso: lesson_slug "2026-02-22-livewire-alpine-morph.md"
lesson_slug() {
    local basename=$(basename "$1" .md)
    # Remove prefixo de data
    echo "$basename" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//'
}

# Verifica se uma lição já foi promovida a regra
# Retorna 0 se já promovida, 1 se não
is_already_promoted() {
    local file="$1"
    local rules_dir="$AIDEV_ROOT/rules"

    # Verificar em todos os arquivos de regras se existe referência à lição
    if grep -rql "$(basename "$file")" "$rules_dir"/*.md 2>/dev/null; then
        return 0
    fi
    return 1
}

# Extrai seção de um markdown por header
# Uso: extract_section "conteúdo" "Solução"
extract_section() {
    local content="$1"
    local section_name="$2"

    echo "$content" | awk -v name="$section_name" '
        BEGIN { found=0; buffer="" }
        /^##/ {
            if (found) exit
            if (tolower($0) ~ tolower(name)) found=1
            next
        }
        found { buffer = buffer $0 "\n" }
        END { if (buffer != "") print buffer }
    '
}

# Detecta a stack de uma lição pelo conteúdo
detect_lesson_stack() {
    local content="$1"

    if echo "$content" | grep -qiE "Laravel|Livewire|Blade|Eloquent|artisan|PHP|Filament"; then
        echo "laravel"
    elif echo "$content" | grep -qiE "React|Next\.js|Vue|Angular"; then
        echo "frontend"
    elif echo "$content" | grep -qiE "Python|Django|Flask|FastAPI"; then
        echo "python"
    elif echo "$content" | grep -qiE "Node\.js|Express|Deno|Bun"; then
        echo "nodejs"
    else
        echo "generic"
    fi
}

# Promove uma lição a regra
# Uso: promote_lesson "/path/to/lesson.md"
# Retorno: 0 = sucesso, 1 = falha/inelegível
promote_lesson() {
    local file="$1"
    local force="${2:-false}"
    [ ! -f "$file" ] && { echo "  ✗ Arquivo não encontrado: $file" >&2; return 1; }

    local basename=$(basename "$file")

    # Verificar scope
    local scope=$(classify_lesson_scope "$file")
    if [ "$scope" = "local" ] && [ "$force" != "true" ]; then
        echo "  ⊘ $basename: scope local — não elegível para promoção"
        return 1
    fi

    # Verificar se já promovida
    if is_already_promoted "$file"; then
        echo "  ℹ $basename: já promovida a regra"
        return 0
    fi

    # Extrair dados da lição
    local content=$(cat "$file")
    local slug=$(lesson_slug "$file")
    local titulo=$(echo "$content" | grep -m1 '^#' | sed 's/^#*\s*//')
    local problema=$(extract_section "$content" "Problema")
    local solucao=$(extract_section "$content" "Solução")
    local prevencao=$(extract_section "$content" "Prevenção")
    local stack=$(detect_lesson_stack "$content")
    local rules_file="$AIDEV_ROOT/rules/${stack}.md"
    local today=$(date +%Y-%m-%d)

    # Verificar conteúdo mínimo
    if [ -z "$solucao" ] && [ -z "$problema" ]; then
        echo "  ⚠ $basename: sem seções Problema/Solução — impossível gerar regra"
        return 1
    fi

    # Criar/atualizar arquivo de regras
    mkdir -p "$(dirname "$rules_file")"

    # Se arquivo não existe, criar header
    if [ ! -f "$rules_file" ]; then
        cat > "$rules_file" <<EOF
# ${stack^} Stack Rules

## Regras derivadas de lições aprendidas
Estas regras foram promotionadas automaticamente a partir de lições validadas.

EOF
    fi

    # Gerar bloco de regra
    local rule_block="
---

## Regra: ${titulo:-$slug}

**Origem**: \`$(basename "$file")\`
**Promovida em**: $today
**Scope**: $scope

### Quando Aplicar
${problema:-Quando encontrar o padrão descrito abaixo.}

### Regra
${solucao:-Ver lição original.}

### Prevenção
${prevencao:-Seguir a regra acima proativamente.}
"

    # Append ao arquivo de regras
    echo "$rule_block" >> "$rules_file"

    echo "  ✓ $basename → $rules_file (scope: $scope, stack: $stack)"
    return 0
}

# Promove todas as lições elegíveis (global + universal)
# Uso: promote_eligible_lessons
promote_eligible_lessons() {
    local kb_dir="$AIDEV_ROOT/memory/kb"
    [ ! -d "$kb_dir" ] && { echo "Diretório KB não encontrado"; return 1; }

    local total=0
    local promoted=0
    local skipped=0

    echo "=== Promoção de Lições a Regras ==="
    for file in "$kb_dir"/*.md; do
        [ ! -f "$file" ] && continue
        ((total++))

        if promote_lesson "$file" 2>/dev/null; then
            ((promoted++))
        else
            ((skipped++))
        fi
    done

    echo ""
    echo "=== Resumo ==="
    echo "Total: $total | Promovidas: $promoted | Não-elegíveis: $skipped"
}
