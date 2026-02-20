#!/bin/bash
# mcp-detect.sh - Detecção unificada de MCPs multi-runtime
# Sprint 1: basic-memory-graceful-integration
#
# Estratégia de detecção em 2 camadas:
#   Camada 1: Variáveis de ambiente explícitas (BASIC_MEMORY_ENABLED, MCP_BASIC_MEMORY_AVAILABLE)
#   Camada 2: Presença em .mcp.json + capacidade por runtime

_SCRIPT_DIR_MCP_DETECT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Importa detect_runtime canônica se ainda não disponível
if ! type detect_runtime &>/dev/null; then
    # shellcheck source=activation-snapshot.sh
    source "$_SCRIPT_DIR_MCP_DETECT/activation-snapshot.sh" 2>/dev/null || true
fi

# ============================================================================
# mcp_detect_basic_memory
# Detecta se o Basic Memory MCP está disponível no runtime atual.
#
# Cache: resultado armazenado em _AIDEV_BM_DETECTED para evitar re-detecção.
# Retorna: 0 (disponível) | 1 (não disponível)
# ============================================================================
mcp_detect_basic_memory() {
    # Cache: evita re-detecção na mesma sessão
    if [ -n "${_AIDEV_BM_DETECTED+x}" ]; then
        return "$_AIDEV_BM_DETECTED"
    fi

    local result=1

    # Camada 1: variável explícita (setada pelo usuário ou wrapper de launch)
    if [ "${BASIC_MEMORY_ENABLED:-false}" = "true" ] || \
       [ -n "${MCP_BASIC_MEMORY_AVAILABLE:-}" ]; then
        result=0

    # Camada 2: presença em .mcp.json (declarativa, runtime-agnóstica)
    elif [ -f ".mcp.json" ] && grep -q '"basic-memory"' ".mcp.json" 2>/dev/null; then
        local runtime
        runtime=$(detect_runtime 2>/dev/null || echo "unknown")

        case "$runtime" in
            claude_code)
                # Claude Code: confirmar via type (funções bash injetadas pelo MCP)
                type mcp__basic-memory__write_note &>/dev/null && result=0
                ;;
            antigravity)
                # Antigravity: MCPs declarados em .mcp.json são expostos automaticamente
                result=0
                ;;
            gemini|opencode|*)
                # Outros runtimes: confirmar via CLI instalado
                command -v basic-memory &>/dev/null && result=0
                ;;
        esac
    fi

    export _AIDEV_BM_DETECTED=$result
    return $result
}

# ============================================================================
# mcp_detect_available <nome-do-mcp>
# Detecção genérica para qualquer MCP declarado em .mcp.json.
#
# Parâmetros:
#   $1 — nome do MCP (ex: "github", "filesystem")
# Retorna: 0 (disponível) | 1 (não disponível)
# ============================================================================
mcp_detect_available() {
    local mcp_name="${1:-}"
    [ -z "$mcp_name" ] && return 1

    # Verificação rápida via .mcp.json
    [ -f ".mcp.json" ] || return 1
    grep -q "\"${mcp_name}\"" ".mcp.json" 2>/dev/null || return 1

    local runtime
    runtime=$(detect_runtime 2>/dev/null || echo "unknown")

    case "$runtime" in
        claude_code)
            # Verifica se função bash do MCP está injetada
            local fn_name
            fn_name="mcp__${mcp_name}__"
            # type com prefixo — verifica se existe alguma função do MCP
            type "${fn_name}write_note" &>/dev/null || \
            type "${fn_name}search" &>/dev/null || \
            type "${fn_name}read" &>/dev/null && return 0
            return 1
            ;;
        antigravity)
            # MCPs declarados em .mcp.json são sempre expostos no Antigravity
            return 0
            ;;
        *)
            # Tenta via CLI com nome do MCP
            command -v "$mcp_name" &>/dev/null && return 0
            return 1
            ;;
    esac
}
