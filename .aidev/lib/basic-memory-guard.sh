#!/bin/bash
# basic-memory-guard.sh - Wrappers seguros para Basic Memory MCP
# Sprint 2: basic-memory-graceful-integration
#
# Camada de proteção bash: cada função verifica disponibilidade via mcp_detect_basic_memory()
# e faz fallback local quando o MCP não está disponível.
#
# Uso: source .aidev/lib/basic-memory-guard.sh

_SCRIPT_DIR_BM_GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carrega detecção unificada se ainda não disponível
if ! type mcp_detect_basic_memory &>/dev/null; then
    source "$_SCRIPT_DIR_BM_GUARD/mcp-detect.sh" 2>/dev/null || true
fi

# Diretório local de fallback (relativo ao CWD do projeto)
_BM_LOCAL_DIR="${BM_LOCAL_DIR:-.aidev/memory/kb}"

# ============================================================================
# WRAPPERS PÚBLICOS
# ============================================================================

# bm_write_note <titulo> <conteudo> [diretorio]
# Salva nota no Basic Memory. Fallback: arquivo local em .aidev/memory/kb/
bm_write_note() {
    local title="$1"
    local content="$2"
    local directory="${3:-kb}"

    if mcp_detect_basic_memory 2>/dev/null; then
        mcp__basic-memory__write_note title="$title" content="$content" directory="$directory"
        return $?
    fi

    _bm_fallback_write "$title" "$content" "$directory"
}

# bm_search <query> [max_resultados]
# Busca no Basic Memory. Fallback: grep local em .aidev/memory/kb/
bm_search() {
    local query="$1"
    local max="${2:-5}"

    if mcp_detect_basic_memory 2>/dev/null; then
        mcp__basic-memory__search_notes query="$query"
        return $?
    fi

    _bm_fallback_search "$query" "$max"
}

# bm_build_context <url>
# Constrói contexto do Basic Memory. Fallback: lê checkpoint + activation_context local.
bm_build_context() {
    local url="$1"

    if mcp_detect_basic_memory 2>/dev/null; then
        mcp__basic-memory__build_context url="$url"
        return $?
    fi

    _bm_fallback_context
}

# ============================================================================
# FALLBACKS LOCAIS
# ============================================================================

# Salva nota como arquivo markdown local
_bm_fallback_write() {
    local title="$1"
    local content="$2"
    local directory="${3:-kb}"

    local dest_dir="$_BM_LOCAL_DIR/$directory"
    mkdir -p "$dest_dir" 2>/dev/null || true

    local file_path="$_BM_LOCAL_DIR/${title}.md"
    printf '%s\n' "$content" > "$file_path" 2>/dev/null || {
        # fallback para subdiretório se título com barra
        file_path="$dest_dir/${title##*/}.md"
        printf '%s\n' "$content" > "$file_path"
    }
    return 0
}

# Busca por grep recursivo nos arquivos locais
_bm_fallback_search() {
    local query="$1"
    local max="${2:-5}"

    local search_dir="$_BM_LOCAL_DIR"
    [ -d "$search_dir" ] || { echo "[]"; return 0; }

    grep -rl "$query" "$search_dir" 2>/dev/null | head -"$max" || true
    return 0
}

# Lê checkpoint e activation_context locais como contexto substituto
_bm_fallback_context() {
    local state_dir=".aidev/state"

    if [ -f "$state_dir/checkpoint.md" ]; then
        echo "=== Checkpoint Local ==="
        cat "$state_dir/checkpoint.md"
        echo ""
    fi

    if [ -f "$state_dir/activation_context.md" ]; then
        echo "=== Contexto de Ativação ==="
        cat "$state_dir/activation_context.md"
        echo ""
    fi

    return 0
}
