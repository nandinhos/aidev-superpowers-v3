#!/usr/bin/env bash

# ============================================================================
# AI Dev Superpowers V3 - Manifest Module
# ============================================================================
# Classificacao declarativa de arquivos com politicas por categoria.
# Consulta MANIFEST.json para determinar como tratar cada arquivo
# durante upgrade, init e operacoes de escrita.
# ============================================================================

# Estado interno do manifesto carregado
declare -g MANIFEST_LOADED=false
declare -g MANIFEST_FILE=""
declare -g MANIFEST_VERSION=""

# ============================================================================
# manifest_load - Carrega MANIFEST.json
# ============================================================================
# Uso: AIDEV_ROOT_DIR="/path" manifest_load
# Retorna: 0 sucesso, 1 falha
manifest_load() {
    local manifest_path="${AIDEV_ROOT_DIR:-}/MANIFEST.json"

    if [ ! -f "$manifest_path" ]; then
        MANIFEST_LOADED=false
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        MANIFEST_LOADED=false
        return 1
    fi

    # Validar JSON basico
    if ! jq empty "$manifest_path" 2>/dev/null; then
        MANIFEST_LOADED=false
        return 1
    fi

    MANIFEST_FILE="$manifest_path"
    MANIFEST_VERSION=$(jq -r '.manifest_version // empty' "$manifest_path")
    MANIFEST_LOADED=true
    return 0
}

# ============================================================================
# manifest_get_policy - Retorna politica para um filepath
# ============================================================================
# Uso: manifest_get_policy ".aidev/agents/orchestrator.md"
# Retorna: string com a politica (stdout) ou "unknown"
manifest_get_policy() {
    local filepath="$1"

    if [ "$MANIFEST_LOADED" != "true" ]; then
        echo "unknown"
        return 1
    fi

    local category=""
    category=$(_manifest_match_category "$filepath")

    if [ -z "$category" ]; then
        echo "unknown"
        return 0
    fi

    local policy=""
    policy=$(jq -r --arg cat "$category" '.categories[$cat].policy // "unknown"' "$MANIFEST_FILE")
    echo "$policy"
    return 0
}

# ============================================================================
# manifest_is_protected - Verifica se arquivo eh protegido
# ============================================================================
# Protegido = core, state ou user (nao deve ser tocado em upgrade)
# Uso: manifest_is_protected ".aidev/state/unified.json" && echo "protegido"
# Retorna: 0 se protegido, 1 se nao protegido
manifest_is_protected() {
    local filepath="$1"
    local policy=""
    policy=$(manifest_get_policy "$filepath")

    case "$policy" in
        never_modify_in_project|never_overwrite|never_touch)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# manifest_validate - Valida estrutura do MANIFEST.json
# ============================================================================
# Uso: manifest_validate
# Retorna: 0 se valido, 1 se invalido
manifest_validate() {
    local manifest_path="${AIDEV_ROOT_DIR:-}/MANIFEST.json"

    if [ ! -f "$manifest_path" ]; then
        return 1
    fi

    if ! command -v jq &>/dev/null; then
        return 1
    fi

    # Validar JSON
    if ! jq empty "$manifest_path" 2>/dev/null; then
        return 1
    fi

    # Validar campos obrigatorios
    local version=""
    version=$(jq -r '.manifest_version // empty' "$manifest_path")
    if [ -z "$version" ]; then
        return 1
    fi

    local has_categories=""
    has_categories=$(jq -r '.categories // empty | keys | length' "$manifest_path" 2>/dev/null)
    if [ -z "$has_categories" ] || [ "$has_categories" -eq 0 ]; then
        return 1
    fi

    local has_files=""
    has_files=$(jq -r '.files // empty | keys | length' "$manifest_path" 2>/dev/null)
    if [ -z "$has_files" ] || [ "$has_files" -eq 0 ]; then
        return 1
    fi

    return 0
}

# ============================================================================
# _manifest_match_category - Funcao interna de glob matching
# ============================================================================
# Percorre as entradas de files no manifesto e retorna a categoria
# do primeiro glob que faz match com o filepath.
_manifest_match_category() {
    local filepath="$1"

    if [ "$MANIFEST_LOADED" != "true" ]; then
        return 1
    fi

    # Extrair pares glob:category do manifesto
    local pairs=""
    pairs=$(jq -r '.files | to_entries[] | "\(.key)|\(.value)"' "$MANIFEST_FILE" 2>/dev/null)

    local glob_pattern category
    while IFS='|' read -r glob_pattern category; do
        if _manifest_glob_match "$filepath" "$glob_pattern"; then
            echo "$category"
            return 0
        fi
    done <<< "$pairs"

    return 1
}

# ============================================================================
# _manifest_glob_match - Glob matching simplificado
# ============================================================================
# Suporta: *, ** e patterns basicos de glob
# Uso: _manifest_glob_match "path/to/file" "path/*/file"
_manifest_glob_match() {
    local filepath="$1"
    local pattern="$2"

    # Converter ** para pattern que funciona com bash extglob
    # ** = qualquer profundidade de diretorio
    local bash_pattern="${pattern}"

    # Substituir ** por catch-all (qualquer coisa incluindo /)
    bash_pattern="${bash_pattern//\*\*/*}"

    # Usar extglob para matching
    # shellcheck disable=SC2254
    if [[ "$filepath" == $bash_pattern ]]; then
        return 0
    fi

    return 1
}
