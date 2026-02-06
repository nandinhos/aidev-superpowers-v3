#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Cache Module
# ============================================================================
# Sistema de cache inteligente para ativação do agente
# Reduz consumo de tokens armazenando contexto consolidado
#
# Uso: source lib/cache.sh
# Dependências: lib/core.sh
# ============================================================================

# Diretório de cache (dentro do projeto)
CACHE_DIR=".aidev/.cache"
CACHE_FILE="activation_cache.json"

# ============================================================================
# Hash Generation
# ============================================================================

# Gera hash dos arquivos .aidev para validação de freshness
# Uso: get_aidev_hash "/path/to/project"
# Retorna: SHA256 hash string
get_aidev_hash() {
    local project_path="${1:-.}"
    local aidev_dir="$project_path/.aidev"
    
    if [ ! -d "$aidev_dir" ]; then
        echo "no_aidev_dir"
        return 1
    fi
    
    # Concatena conteúdo de todos os arquivos relevantes e gera hash
    local hash_input=""
    
    # Enable nullglob to handle empty globs
    shopt -s nullglob
    
    # Agents
    for f in "$aidev_dir"/agents/*.md; do
        [ -f "$f" ] && hash_input+=$(cat "$f" 2>/dev/null)
    done
    
    # Skills (apenas diretórios)
    for d in "$aidev_dir"/skills/*/; do
        [ -d "$d" ] && hash_input+=$(basename "$d")
    done
    
    # Rules
    for f in "$aidev_dir"/rules/*.md; do
        [ -f "$f" ] && hash_input+=$(cat "$f" 2>/dev/null)
    done
    
    # Disable nullglob
    shopt -u nullglob

    
    # Gera hash
    if command -v sha256sum &>/dev/null; then
        echo "$hash_input" | sha256sum | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        echo "$hash_input" | shasum -a 256 | cut -d' ' -f1
    else
        # Fallback: usar md5
        echo "$hash_input" | md5sum | cut -d' ' -f1
    fi
}

# ============================================================================
# Cache Generation
# ============================================================================

# Gera cache de ativação consolidado em JSON
# Uso: generate_activation_cache "/path/to/project"
# Retorna: JSON string com dados de cache
generate_activation_cache() {
    local project_path="${1:-.}"
    local aidev_dir="$project_path/.aidev"
    
    if [ ! -d "$aidev_dir" ]; then
        echo '{"error": "no_aidev_dir"}'
        return 1
    fi
    
    # Coletar agentes com metadados
    local agents=()
    local agent_details_json=""
    shopt -s nullglob
    for f in "$aidev_dir"/agents/*.md; do
        if [ -f "$f" ]; then
            local name=$(basename "${f%.md}")
            agents+=("$name")
            
            # Extrair Role ou Identity (primeira linha util após header ## Role ou # Identity)
            local role=$(grep -A 2 -E "## Role|# Identity" "$f" | grep -vE "## Role|# Identity|^--" | grep -v "^$" | head -n 1 | sed 's/[#*`]//g' | tr '\n' ' ' | sed 's/"/\\"/g' | xargs | head -c 200)
            
            if [ -z "$role" ]; then
                # Fallback: pegar primeira linha útil do arquivo que não seja header
                role=$(grep -vE "^#|^$" "$f" | head -n 1 | sed 's/[#*`]//g' | tr '\n' ' ' | sed 's/"/\\"/g' | xargs | head -c 200)
            fi

            if [ -n "$agent_details_json" ]; then agent_details_json+=", "; fi
            agent_details_json+="\"$name\": \"$role\""
        fi
    done

    # Coletar skills
    local skills=()
    for d in "$aidev_dir"/skills/*/; do
        [ -d "$d" ] && skills+=("$(basename "$d")")
    done
    
    # Coletar regras
    local rules=()
    for f in "$aidev_dir"/rules/*.md; do
        [ -f "$f" ] && rules+=("$(basename "${f%.md}")")
    done
    shopt -u nullglob

    # Gerar hash
    local hash
    hash=$(get_aidev_hash "$project_path")
    
    # Detectar projeto e stack
    local project_name
    project_name=$(basename "$(cd "$project_path" && pwd)")
    
    local stack="generic"
    if [ -f "$project_path/composer.json" ]; then
        stack="laravel"
    elif [ -f "$project_path/package.json" ]; then
        stack="node"
    elif [ -f "$project_path/requirements.txt" ]; then
        stack="python"
    fi
    
    # Versão do aidev
    local version="${AIDEV_VERSION:-3.8.1}"
    
    # Gerar JSON manualmente (para compatibilidade)
    local agents_json=""
    for a in "${agents[@]}"; do
        [ -n "$agents_json" ] && agents_json+=", "
        agents_json+="\"$a\""
    done
    
    local skills_json=""
    for s in "${skills[@]}"; do
        [ -n "$skills_json" ] && skills_json+=", "
        skills_json+="\"$s\""
    done
    
    local rules_json=""
    for r in "${rules[@]}"; do
        [ -n "$rules_json" ] && rules_json+=", "
        rules_json+="\"$r\""
    done
    
    cat <<EOF
{
  "version": "$version",
  "generated_at": "$(date -Iseconds)",
  "hash": "$hash",
  "project": "$project_name",
  "stack": "$stack",
  "agents": [$agents_json],
  "agent_roles": {$agent_details_json},
  "skills": [$skills_json],
  "rules": [$rules_json],
  "agents_count": ${#agents[@]},
  "skills_count": ${#skills[@]}
}
EOF
}

# ============================================================================
# Cache Validation
# ============================================================================

# Valida se o cache está fresco (não expirado)
# Uso: validate_cache_freshness "/path/to/project"
# Retorna: 0 se válido, 1 se inválido
validate_cache_freshness() {
    local project_path="${1:-.}"
    local cache_file="$project_path/$CACHE_DIR/$CACHE_FILE"
    
    # Se cache não existe, é inválido
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    # Extrair hash do cache
    local cached_hash
    cached_hash=$(grep -o '"hash": *"[^"]*"' "$cache_file" | cut -d'"' -f4)
    
    # Gerar hash atual
    local current_hash
    current_hash=$(get_aidev_hash "$project_path")
    
    # Comparar
    if [ "$cached_hash" = "$current_hash" ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Cache Retrieval
# ============================================================================

# Obtém cache de ativação se válido
# Uso: get_cached_activation "/path/to/project"
# Retorna: JSON do cache ou vazio se inválido
get_cached_activation() {
    local project_path="${1:-.}"
    local cache_file="$project_path/$CACHE_DIR/$CACHE_FILE"
    
    if validate_cache_freshness "$project_path"; then
        cat "$cache_file"
        return 0
    else
        return 1
    fi
}

# Salva cache de ativação
# Uso: save_activation_cache "/path/to/project"
save_activation_cache() {
    local project_path="${1:-.}"
    local cache_dir="$project_path/$CACHE_DIR"
    local cache_file="$cache_dir/$CACHE_FILE"
    
    # Criar diretório se necessário
    mkdir -p "$cache_dir"
    
    # Gerar e salvar cache
    generate_activation_cache "$project_path" > "$cache_file"
    
    return 0
}

# Invalida (remove) o cache
# Uso: invalidate_cache "/path/to/project"
invalidate_cache() {
    local project_path="${1:-.}"
    local cache_file="$project_path/$CACHE_DIR/$CACHE_FILE"
    
    if [ -f "$cache_file" ]; then
        rm -f "$cache_file"
    fi
    
    return 0
}

# ============================================================================
# CLI Helper
# ============================================================================

# Exibe status do cache
# Uso: show_cache_status "/path/to/project"
show_cache_status() {
    local project_path="${1:-.}"
    local cache_file="$project_path/$CACHE_DIR/$CACHE_FILE"
    
    echo ""
    if [ -f "$cache_file" ]; then
        if validate_cache_freshness "$project_path"; then
            echo -e "${GREEN:-}✓${NC:-} Cache válido"
        else
            echo -e "${YELLOW:-}⚠${NC:-} Cache desatualizado"
        fi
        
        # Mostrar info do cache
        local version hash generated_at
        version=$(grep -o '"version": *"[^"]*"' "$cache_file" | cut -d'"' -f4)
        hash=$(grep -o '"hash": *"[^"]*"' "$cache_file" | cut -d'"' -f4 | head -c 12)
        generated_at=$(grep -o '"generated_at": *"[^"]*"' "$cache_file" | cut -d'"' -f4)
        
        echo "  Versão:    $version"
        echo "  Hash:      ${hash}..."
        echo "  Gerado em: $generated_at"
    else
        echo -e "${GREY:-}○${NC:-} Sem cache"
    fi
    echo ""
}
