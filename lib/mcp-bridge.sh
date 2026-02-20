#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3.8 - MCP Bridge Module
# ============================================================================
# Camada de abstração para integração inteligente com o ecossistema MCP.
#
# Uso: source lib/mcp-bridge.sh
# Dependências: lib/core.sh, lib/detection.sh
# ============================================================================

# Variáveis globais
MCP_BRIDGE_STATUS="idle"

# Inicializa a ponte MCP
# Uso: mcp_bridge_init
mcp_bridge_init() {
    print_debug "Inicializando MCP Bridge..."
    MCP_BRIDGE_STATUS="ready"
}

# Verifica se um servidor MCP está disponível e funcional no ambiente
# Uso: if mcp_bridge_check "basic-memory"; then ...
# Delega para mcp_detect_available (Sprint 1: basic-memory-graceful-integration)
mcp_bridge_check() {
    local server_name="$1"

    # Tenta carregar detecção unificada se disponível
    local aidev_lib
    aidev_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.aidev/lib" 2>/dev/null && pwd)"
    if [ -f "$aidev_lib/mcp-detect.sh" ] && ! type mcp_detect_available &>/dev/null; then
        source "$aidev_lib/mcp-detect.sh" 2>/dev/null || true
    fi

    if type mcp_detect_available &>/dev/null; then
        mcp_detect_available "$server_name"
        return $?
    fi

    # Fallback legado: Antigravity assume MCPs disponíveis
    [ -n "$ANTIGRAVITY_AGENT" ] && return 0
    return 1
}

# Sugere servidores MCP baseados na detecção de stack
# Uso: mcp_bridge_suggest
mcp_bridge_suggest() {
    detect_project_context
    
    local suggested="$DETECTED_MCP_COMPATIBILITY"
    
    if [ -n "$suggested" ]; then
        print_section "Sugestão de Ecossistema MCP"
        print_info "Baseado na stack detectada ($DETECTED_STACK), recomendamos:"
        
        IFS=',' read -ra ADDR <<< "$suggested"
        for mcp in "${ADDR[@]}"; do
            case "$mcp" in
                "laravel-boost")
                    print_info "  - [laravel-boost]: Otimizado para apps PHP/Laravel/Filament"
                    ;;
                "context7")
                    print_info "  - [context7]: Documentação e snippets para $DETECTED_LANGUAGE"
                    ;;
            esac
        done
        echo ""
        print_info "Agentes especializados (como o Architect) usarão essas ferramentas se disponíveis."
    fi
}

# Wrapper para execução de comandos especializados (Bridge)
# Uso: mcp_bridge_exec "laravel-boost" "database-schema"
mcp_bridge_exec() {
    local server="$1"
    local tool="$2"
    shift 2
    local args="$*"
    
    print_debug "MCP Bridge: Roteando para $server/$tool (Args: $args)"
    
    if ! mcp_bridge_check "$server"; then
        print_error "Servidor MCP '$server' nao disponivel no ambiente atual."
        return 1
    fi

    # Lógica de ponte: Dependendo do servidor, podemos ter wrappers específicos
    case "$server" in
        "laravel-boost")
            # Ex: Se o usuário rodar 'aidev mcp exec laravel-boost database-schema'
            # Isso poderia chamar via terminal ou MCP CLI se existisse.
            # No contexto do Antigravity, orientamos o Agente a usar a ferramenta diretamente.
            print_info "💡 [BRIDGE] Para executar ferramentas do $server, use o MCP Laravel Boost diretamente."
            print_info "Comando sugerido: $tool $args"
            ;;
        *)
            print_warning "Bridge genérica para '$server' ainda não implementada."
            ;;
    esac
}
