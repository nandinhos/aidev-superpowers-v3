#!/bin/bash
# kb-search.sh - Motor de busca em Knowledge Base
# Busca em lições aprendidas com relevance scoring e integração MCP

KB_DIR="${KB_DIR:-.aidev/memory/kb}"
KB_INDEX="${KB_INDEX:-.aidev/state/kb-index.json}"

# Carrega detecção unificada de MCPs (Sprint 1: basic-memory-graceful-integration)
_KB_SEARCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_KB_SEARCH_DIR/mcp-detect.sh" 2>/dev/null || true

# ============================================================================
# VERIFICAÇÃO DE MCPs
# ============================================================================

_kb_check_mcp_availability() {
    local available_mcp=()

    # Verifica Basic Memory via detecção unificada multi-runtime
    if mcp_detect_basic_memory 2>/dev/null; then
        available_mcp+=("basic-memory")
    fi

    # Verifica Serena
    if [ -n "$MCP_SERENA_AVAILABLE" ] || command -v serena &>/dev/null; then
        available_mcp+=("serena")
    fi

    echo "${available_mcp[@]}"
}

_kb_show_mcp_notice() {
    echo "[KB-SEARCH] ℹ️  MCPs não disponíveis. Instale para economizar tokens:"
    echo "    - Basic Memory: npm install -g @anthropics/basic-memory"
    echo "    - Serena: pip install serena-mcp"
    echo "    💡 Sem MCPs, busca é local apenas (mais tokens consumidos)"
}

# ============================================================================
# BUSCA LOCAL
# ============================================================================

kb_search_local() {
    local query="$1"
    local max_results="${2:-5}"
    
    # Normaliza query para minúsculas e remove caracteres especiais
    local normalized=$(echo "$query" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]/ /g')
    local keywords=($normalized)
    local results="[]"
    
    if [ ! -d "$KB_DIR" ]; then
        echo "$results"
        return
    fi
    
    # Percorre todos os arquivos .md no KB
    for file in "$KB_DIR"/*.md; do
        [ -e "$file" ] || continue
        
        local filename=$(basename "$file")
        local content=$(cat "$file" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        local score=0
        local matched_keywords=""
        
        # Calcula score baseado em ocorrências de keywords
        for keyword in "${keywords[@]}"; do
            [ -z "$keyword" ] && continue
            
            local count=$(echo "$content" | grep -o "$keyword" | wc -l)
            if [ "$count" -gt 0 ]; then
                score=$((score + count * 10))
                matched_keywords="$matched_keywords $keyword"
            fi
        done
        
        # Bônus por campos específicos no frontmatter
        if echo "$content" | grep -q "type:.*bug"; then
            score=$((score + 20))
        fi
        if echo "$content" | grep -q "category:.*critical"; then
            score=$((score + 30))
        fi
        if echo "$content" | grep -q "category:.*security"; then
            score=$((score + 25))
        fi
        
        # Bônus se keyword está no título
        local title=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //' | tr '[:upper:]' '[:lower:]')
        for keyword in "${keywords[@]}"; do
            if [[ "$title" == *"$keyword"* ]]; then
                score=$((score + 50))
            fi
        done
        
        # Extrai metadata
        local id=$(grep "^id:" "$file" 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' ')
        local category=$(grep "^category:" "$file" 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' ')
        local resolved_at=$(grep "^resolved_at:" "$file" 2>/dev/null | head -1 | cut -d: -f2- | tr -d ' ')
        
        if [ $score -gt 0 ]; then
            local entry=$(jq -n \
                --arg id "${id:-$filename}" \
                --arg title "$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //')" \
                --arg file "$filename" \
                --argjson score "$score" \
                --arg source "local" \
                --arg category "$category" \
                --arg keywords "$matched_keywords" \
                --arg date "$resolved_at" \
                '{
                    id: $id,
                    title: $title,
                    file: $file,
                    score: $score,
                    source: $source,
                    category: $category,
                    matched_keywords: $keywords,
                    resolved_at: $date
                }')
            results=$(echo "$results" | jq ". += [$entry]")
        fi
    done
    
    # Ordena por score e limita resultados
    echo "$results" | jq "sort_by(.score) | reverse | .[0:$max_results]"
}

# ============================================================================
# BUSCA MCP (PLACEHOLDERS)
# ============================================================================

kb_search_basic_memory() {
    local query="$1"
    local max_results="$2"
    
    # Placeholder para quando MCP estiver disponível
    # Comando real: mcp__basic-memory__search_notes query="$query"
    echo "[]"
}

kb_search_serena() {
    local query="$1"
    local max_results="$2"
    
    # Placeholder para quando MCP estiver disponível
    # Comando real: mcp__serena__search_memories query="$query"
    echo "[]"
}

# ============================================================================
# BUSCA PRINCIPAL
# ============================================================================

kb_search() {
    local query="$1"
    local max_results="${2:-5}"
    local use_mcp="${3:-true}"
    
    if [ -z "$query" ]; then
        echo "[]"
        return 0
    fi
    
    log_kb_search "INFO" "kb_search" "Iniciando busca: '$query' (max: $max_results)"
    
    local all_results="[]"
    
    # 1. Busca local (sempre executa)
    log_kb_search "INFO" "kb_search" "Buscando em KB local..."
    local local_results=$(kb_search_local "$query" "$max_results")
    local local_count=$(echo "$local_results" | jq 'length')
    all_results=$(echo "$all_results" | jq --argjson local "$local_results" '. + $local')
    
    log_kb_search "INFO" "kb_search" "Encontradas $local_count lições localmente"
    
    # 2. Busca em MCPs (se disponível e permitido)
    if [ "$use_mcp" == "true" ]; then
        local mcp_list=$(_kb_check_mcp_availability)
        
        if [[ "$mcp_list" == *"basic-memory"* ]]; then
            log_kb_search "INFO" "kb_search" "Buscando em Basic Memory MCP..."
            local mcp_results=$(kb_search_basic_memory "$query" "$max_results")
            all_results=$(echo "$all_results" | jq --argjson mcp "$mcp_results" '. + $mcp')
            echo "[KB-SEARCH] MCP Basic Memory: ✓ Tokens economizados com busca semântica" >&2
        fi
        
        if [[ "$mcp_list" == *"serena"* ]]; then
            log_kb_search "INFO" "kb_search" "Buscando em Serena MCP..."
            local serena_results=$(kb_search_serena "$query" "$max_results")
            all_results=$(echo "$all_results" | jq --argjson serena "$serena_results" '. + $serena')
            echo "[KB-SEARCH] MCP Serena: ✓ Contexto de sessão recuperado" >&2
        fi
        
        if [ -z "$mcp_list" ]; then
            _kb_show_mcp_notice >&2
        fi
    fi
    
    # Remove duplicados (por id), ordena por score e limita
    local final_results=$(echo "$all_results" | jq 'group_by(.id) | map(first) | sort_by(.score) | reverse | .[0:'"$max_results"']')
    local total_count=$(echo "$final_results" | jq 'length')
    
    log_kb_search "INFO" "kb_search" "Busca completa: $total_count resultados"
    
    echo "$final_results"
}

# ============================================================================
# BUSCA POR CATEGORIA
# ============================================================================

kb_search_by_category() {
    local category="$1"
    local max_results="${2:-10}"
    
    local results="[]"
    
    if [ ! -d "$KB_DIR" ]; then
        echo "$results"
        return
    fi
    
    for file in "$KB_DIR"/*.md; do
        [ -e "$file" ] || continue
        
        if grep -q "category:.*$category" "$file" 2>/dev/null; then
            local filename=$(basename "$file")
            local title=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //')
            local id=$(grep "^id:" "$file" 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' ')
            
            local entry=$(jq -n \
                --arg id "${id:-$filename}" \
                --arg title "$title" \
                --arg file "$filename" \
                --arg category "$category" \
                '{
                    id: $id,
                    title: $title,
                    file: $file,
                    score: 100,
                    source: "local",
                    category: $category
                }')
            results=$(echo "$results" | jq ". += [$entry]")
        fi
    done
    
    echo "$results" | jq ".[0:$max_results]"
}

# ============================================================================
# HOOK PRÉ-CODING
# ============================================================================

kb_pre_coding_search() {
    local task_description="$1"
    local passport_file="${2:-}"
    
    log_kb_search "INFO" "kb_pre_coding_search" "Consultando KB antes de codificação..."
    
    local start_time=$(date +%s)
    local results=$(kb_search "$task_description" 5 true)
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local count=$(echo "$results" | jq 'length')
    
    if [ "$count" -gt 0 ]; then
        echo "[KB-SEARCH] ✅ Encontradas $count lições relevantes (${duration}s):" >&2
        echo "$results" | jq -r '.[] | "  📄 \(.title) [\(.source)] (score: \(.score))"' >&2
        
        # Adiciona referências ao passport se fornecido
        if [ -n "$passport_file" ] && [ -f "$passport_file" ]; then
            source "${BASH_SOURCE%/*}/context-passport.sh" 2>/dev/null || true
            
            echo "$results" | jq -c '.[]' | while read -r result; do
                local file=$(echo "$result" | jq -r '.file')
                local score=$(echo "$result" | jq -r '.score')
                local id=$(echo "$result" | jq -r '.id')
                
                if command -v passport_add_kb_reference &> /dev/null; then
                    passport_add_kb_reference "$passport_file" "$id" "$file" "$score" 2>/dev/null || true
                fi
            done
        fi
    else
        log_kb_search "INFO" "kb_pre_coding_search" "Nenhuma lição relevante encontrada (${duration}s)"
    fi
    
    echo "$results"
}

# ============================================================================
# VERIFICAÇÃO DE LIÇÕES ANTES DE AÇÃO
# ============================================================================

kb_check_lessons_before_action() {
    local action_description="$1"
    local min_relevance="${2:-50}"
    
    local results=$(kb_search "$action_description" 1)
    local top_score=$(echo "$results" | jq '.[0].score // 0')
    
    if [ "$top_score" -ge "$min_relevance" ]; then
        local lesson=$(echo "$results" | jq -r '.[0]')
        local title=$(echo "$lesson" | jq -r '.title')
        local file=$(echo "$lesson" | jq -r '.file')
        
        echo "⚠️  ATENÇÃO: Lição relevante encontrada para esta ação!" >&2
        echo "   📄 $title" >&2
        echo "   📂 $KB_DIR/$file" >&2
        echo "   💡 Recomendado: Leia esta lição antes de prosseguir" >&2
        
        return 0  # Encontrou lição relevante
    fi
    
    return 1  # Nenhuma lição relevante
}

# ============================================================================
# INDEXAÇÃO (OTIMIZAÇÃO)
# ============================================================================

kb_build_index() {
    log_kb_search "INFO" "kb_build_index" "Construindo índice de KB..."
    
    if [ ! -d "$KB_DIR" ]; then
        echo "{}" > "$KB_INDEX"
        return
    fi
    
    local index="{}"
    
    for file in "$KB_DIR"/*.md; do
        [ -e "$file" ] || continue
        
        local filename=$(basename "$file")
        local id=$(grep "^id:" "$file" 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' ')
        local category=$(grep "^category:" "$file" 2>/dev/null | head -1 | cut -d: -f2 | tr -d ' ')
        local tags=$(grep "^tags:" "$file" 2>/dev/null | head -1 | cut -d: -f2-)
        
        # Extrai palavras-chave do conteúdo
        local keywords=$(cat "$file" 2>/dev/null | grep -oE '[a-zA-Z]{4,}' | sort | uniq -c | sort -rn | head -20 | awk '{print $2}' | tr '\n' ' ')
        
        local entry=$(jq -n \
            --arg file "$filename" \
            --arg id "${id:-$filename}" \
            --arg category "$category" \
            --arg tags "$tags" \
            --arg keywords "$keywords" \
            '{
                file: $file,
                id: $id,
                category: $category,
                tags: $tags,
                keywords: $keywords
            }')
        
        index=$(echo "$index" | jq --arg key "$filename" --argjson value "$entry" '. + {($key): $value}')
    done
    
    mkdir -p "$(dirname "$KB_INDEX")"
    echo "$index" > "$KB_INDEX"
    
    local count=$(echo "$index" | jq 'length')
    log_kb_search "INFO" "kb_build_index" "Índice construído: $count entradas"
}

# ============================================================================
# ESTATÍSTICAS
# ============================================================================

kb_stats() {
    echo "📊 Estatísticas da Knowledge Base"
    echo "════════════════════════════════════"
    
    if [ ! -d "$KB_DIR" ]; then
        echo "KB vazio (diretório não existe)"
        return
    fi
    
    local total_files=$(ls -1 "$KB_DIR"/*.md 2>/dev/null | wc -l)
    local categories=$(grep -h "^category:" "$KB_DIR"/*.md 2>/dev/null | cut -d: -f2 | sort | uniq -c | sort -rn)
    local recent=$(ls -lt "$KB_DIR"/*.md 2>/dev/null | head -6 | tail -5 | awk '{print $9}')
    
    echo "Total de lições: $total_files"
    echo ""
    echo "Por categoria:"
    echo "$categories" | while read -r line; do
        echo "  $line"
    done
    echo ""
    echo "Adicionadas recentemente:"
    echo "$recent" | while read -r file; do
        [ -n "$file" ] && echo "  📄 $(basename "$file")"
    done
    
    if [ -f "$KB_INDEX" ]; then
        local index_date=$(stat -c %y "$KB_INDEX" 2>/dev/null | cut -d' ' -f1)
        echo ""
        echo "Índice atualizado: $index_date"
    fi
}

# ============================================================================
# LOGGING
# ============================================================================

log_kb_search() {
    local level="$1"
    local function="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [$level] [$function] $message" >&2
}

# ============================================================================
# CLI
# ============================================================================

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced
    :
else
    # Executado diretamente
    echo "kb-search.sh - Motor de Busca em Knowledge Base"
    echo ""
    echo "Uso: source kb-search.sh"
    echo ""
    echo "Funções disponíveis:"
    echo "  kb_search <query> [max_results] [use_mcp]"
    echo "  kb_search_by_category <category> [max_results]"
    echo "  kb_pre_coding_search <task_description> [passport_file]"
    echo "  kb_check_lessons_before_action <action> [min_relevance]"
    echo "  kb_build_index"
    echo "  kb_stats"
    echo ""
    echo "Diretório KB: $KB_DIR"
fi
