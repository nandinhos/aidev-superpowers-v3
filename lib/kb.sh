#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Knowledge Base Module
# ============================================================================
# Funções para gerenciamento de lições aprendidas e indexação
# 
# Uso: source lib/kb.sh
# Dependências: lib/core.sh, lib/file-ops.sh
# ============================================================================

# Diretórios padrão
KB_DIR=".aidev/memory/kb"
KB_INDEX_FILE=".aidev/memory/kb/.index.json"
SHARED_KB_DIR="${HOME}/.aidev-shared/kb"

# ============================================================================
# Indexação de Lições
# ============================================================================

# Constrói índice de lições para busca rápida
# Uso: build_lessons_index [path]
build_lessons_index() {
    local install_path="${1:-.}"
    local kb_path="$install_path/$KB_DIR"
    local index_file="$install_path/$KB_INDEX_FILE"
    
    if [ ! -d "$kb_path" ]; then
        print_warning "Diretório KB não encontrado: $kb_path"
        return 1
    fi
    
    # Verifica dependência jq
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq é necessário para indexação"
        return 1
    fi
    
    local lessons=()
    local count=0
    
    # Itera sobre lições
    for lesson_file in "$kb_path"/*.md; do
        [ -f "$lesson_file" ] || continue
        
        local filename=$(basename "$lesson_file")
        local title=$(head -n 1 "$lesson_file" | sed 's/^#\s*//')
        local tags=$(grep -oP '(?<=Tags:\s).*' "$lesson_file" 2>/dev/null | tr ',' '\n' | xargs)
        local created=$(stat -c %Y "$lesson_file" 2>/dev/null || stat -f %m "$lesson_file" 2>/dev/null)
        local keywords=$(grep -oP '(?<=Keywords:\s).*' "$lesson_file" 2>/dev/null || echo "")
        
        # Extrai contexto (primeiras 3 linhas após título)
        local context=$(sed -n '2,4p' "$lesson_file" | tr '\n' ' ' | cut -c1-200)
        
        lessons+=("{\"file\":\"$filename\",\"title\":\"$title\",\"tags\":\"$tags\",\"keywords\":\"$keywords\",\"context\":\"$context\",\"created\":$created}")
        ((count++))
    done
    
    # Gera JSON
    local json_array=$(printf '%s\n' "${lessons[@]}" | jq -s '.')
    
    # Cria objeto de índice
    cat > "$index_file" <<EOF
{
  "version": "1.0",
  "generated_at": "$(date -Iseconds)",
  "total_lessons": $count,
  "lessons": $json_array
}
EOF
    
    print_success "Índice criado: $count lições indexadas"
    return 0
}

# ============================================================================
# Busca de Lições
# ============================================================================

# Busca lições por query
# Uso: search_lessons "docker connection" [path]
search_lessons() {
    local query="$1"
    local install_path="${2:-.}"
    local index_file="$install_path/$KB_INDEX_FILE"
    local max_results="${3:-5}"
    
    if [ ! -f "$index_file" ]; then
        print_warning "Índice não encontrado. Execute 'aidev lessons index' primeiro."
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq é necessário para busca"
        return 1
    fi
    
    # Busca case-insensitive em título, tags, keywords e contexto
    local results=$(jq -r --arg q "$query" '
        .lessons | map(select(
            (.title | ascii_downcase | contains($q | ascii_downcase)) or
            (.tags | ascii_downcase | contains($q | ascii_downcase)) or
            (.keywords | ascii_downcase | contains($q | ascii_downcase)) or
            (.context | ascii_downcase | contains($q | ascii_downcase))
        )) | .[:'"$max_results"']
    ' "$index_file")
    
    echo "$results"
}

# Busca e exibe lições formatadas
# Uso: search_lessons_formatted "docker" [path]
search_lessons_formatted() {
    local query="$1"
    local install_path="${2:-.}"
    
    local results=$(search_lessons "$query" "$install_path")
    local count=$(echo "$results" | jq 'length')
    
    if [ "$count" -eq 0 ]; then
        print_info "Nenhuma lição encontrada para: $query"
        return 0
    fi
    
    print_success "Encontradas $count lições para '$query':"
    echo ""
    
    echo "$results" | jq -r '.[] | "  • \(.title)\n    Arquivo: \(.file)\n    Tags: \(.tags)\n"'
}

# ============================================================================
# Sugestão de Lições Similares
# ============================================================================

# Sugere lição similar baseada em erro detectado
# Uso: suggest_similar_lesson "SQLSTATE[HY000]" [path]
suggest_similar_lesson() {
    local error_pattern="$1"
    local install_path="${2:-.}"
    
    # Extrai keywords do erro
    local keywords=""
    
    # Padrões conhecidos
    case "$error_pattern" in
        *SQLSTATE*)
            keywords="database sql connection"
            ;;
        *"Connection refused"*)
            keywords="connection docker network"
            ;;
        *"Permission denied"*)
            keywords="permission chmod access"
            ;;
        *Exception*|*Error*)
            # Extrai nome da exceção
            keywords=$(echo "$error_pattern" | grep -oP '[A-Z][a-z]+Exception|[A-Z][a-z]+Error' | head -1 | tr '[:upper:]' '[:lower:]')
            ;;
    esac
    
    if [ -n "$keywords" ]; then
        for kw in $keywords; do
            local results=$(search_lessons "$kw" "$install_path" 1)
            local count=$(echo "$results" | jq 'length')
            
            if [ "$count" -gt 0 ]; then
                local title=$(echo "$results" | jq -r '.[0].title')
                local file=$(echo "$results" | jq -r '.[0].file')
                
                echo ""
                print_info "💡 Encontrei uma lição similar!"
                echo "   Título: $title"
                echo "   Arquivo: .aidev/memory/kb/$file"
                echo ""
                return 0
            fi
        done
    fi
    
    return 1
}

# ============================================================================
# Cross-Project Sync
# ============================================================================

# Sincroniza lições com repositório compartilhado
# Uso: sync_lessons_cross_project [path] [tags...]
sync_lessons_cross_project() {
    local install_path="${1:-.}"
    shift
    local tags=("$@")
    
    local kb_path="$install_path/$KB_DIR"
    
    # Cria diretório compartilhado se não existir
    if [ ! -d "$SHARED_KB_DIR" ]; then
        mkdir -p "$SHARED_KB_DIR"
        print_info "Criado diretório compartilhado: $SHARED_KB_DIR"
    fi
    
    local synced=0
    
    for lesson_file in "$kb_path"/*.md; do
        [ -f "$lesson_file" ] || continue
        
        local filename=$(basename "$lesson_file")
        local file_tags=$(grep -oP '(?<=Tags:\s).*' "$lesson_file" 2>/dev/null | tr ',' ' ')
        
        # Verifica se lição tem alguma das tags solicitadas
        local should_sync=false
        for tag in "${tags[@]}"; do
            if echo "$file_tags" | grep -qi "$tag"; then
                should_sync=true
                break
            fi
        done
        
        if [ "$should_sync" = true ]; then
            cp "$lesson_file" "$SHARED_KB_DIR/"
            ((synced++))
        fi
    done
    
    if [ $synced -gt 0 ]; then
        print_success "Sincronizadas $synced lições para $SHARED_KB_DIR"
    else
        print_info "Nenhuma lição correspondente às tags: ${tags[*]}"
    fi
}

# Importa lições do repositório compartilhado
# Uso: import_shared_lessons [path] [tags...]
import_shared_lessons() {
    local install_path="${1:-.}"
    shift
    local tags=("$@")
    
    local kb_path="$install_path/$KB_DIR"
    
    if [ ! -d "$SHARED_KB_DIR" ]; then
        print_warning "Diretório compartilhado não existe: $SHARED_KB_DIR"
        return 1
    fi
    
    local imported=0
    
    for lesson_file in "$SHARED_KB_DIR"/*.md; do
        [ -f "$lesson_file" ] || continue
        
        local filename=$(basename "$lesson_file")
        local file_tags=$(grep -oP '(?<=Tags:\s).*' "$lesson_file" 2>/dev/null | tr ',' ' ')
        
        # Verifica se lição tem alguma das tags solicitadas
        local should_import=false
        if [ ${#tags[@]} -eq 0 ]; then
            should_import=true
        else
            for tag in "${tags[@]}"; do
                if echo "$file_tags" | grep -qi "$tag"; then
                    should_import=true
                    break
                fi
            done
        fi
        
        if [ "$should_import" = true ] && [ ! -f "$kb_path/$filename" ]; then
            cp "$lesson_file" "$kb_path/"
            ((imported++))
        fi
    done
    
    if [ $imported -gt 0 ]; then
        print_success "Importadas $imported lições de $SHARED_KB_DIR"
        # Rebuild index
        build_lessons_index "$install_path"
    else
        print_info "Nenhuma nova lição para importar"
    fi
}
