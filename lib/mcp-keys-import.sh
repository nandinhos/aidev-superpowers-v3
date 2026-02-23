#!/bin/bash

# ============================================================================
# mcp-keys-import.sh - Importa chaves de API de configurações existentes
# ============================================================================
# Origens suportadas:
#   - Antigravity: ~/.gemini/antigravity/mcp_config.json
# ============================================================================

_ANTIGRAVITY_CONFIG="${ANTIGRAVITY_CONFIG:-$HOME/.gemini/antigravity/mcp_config.json}"

mcp_keys_import() {
    local source="${1:-antigravity}"
    local imported=0
    
    echo "🔑 Importando chaves de API..."
    echo ""
    
    case "$source" in
        antigravity)
            if [ ! -f "$_ANTIGRAVITY_CONFIG" ]; then
                echo "❌ Arquivo não encontrado: $_ANTIGRAVITY_CONFIG"
                return 0
            fi
            
            # Context7
            local ctx7_key
            ctx7_key=$(jq -r '.context7.env.CONTEXT7_API_KEY // empty' "$_ANTIGRAVITY_CONFIG" 2>/dev/null || echo "")
            if [ -n "$ctx7_key" ]; then
                export CONTEXT7_API_KEY="$ctx7_key"
                echo "✅ CONTEXT7_API_KEY importada"
                imported=$((imported + 1))
            else
                echo "⚠️  CONTEXT7_API_KEY não encontrada"
            fi
            
            # Basic Memory (se tiver chave)
            local bm_key
            bm_key=$(jq -r '.["basic-memory"].env.BASIC_MEMORY_API_KEY // .basic-memory.env.API_KEY // empty' "$_ANTIGRAVITY_CONFIG" 2>/dev/null || echo "")
            if [ -n "$bm_key" ]; then
                export BASIC_MEMORY_API_KEY="$bm_key"
                echo "✅ BASIC_MEMORY_API_KEY importada"
                imported=$((imported + 1))
            fi
            
            # Serena (verificar se tem chave)
            local serena_key
            serena_key=$(jq -r '.serena.env.SERENA_API_KEY // empty' "$_ANTIGRAVITY_CONFIG" 2>/dev/null || echo "")
            if [ -n "$serena_key" ]; then
                export SERENA_API_KEY="$serena_key"
                echo "✅ SERENA_API_KEY importada"
                imported=$((imported + 1))
            fi
            ;;
            
        *)
            echo "❌ Origem desconhecida: $source"
            echo "Origens suportadas: antigravity"
            return 0
            ;;
    esac
    
    echo ""
    if [ $imported -gt 0 ]; then
        echo "✓ $imported chave(s) importada(s)"
        echo ""
        echo "⚠️  Para persistir, adicione ao seu ~/.bashrc ou ~/.zshrc:"
        echo "   source ~/.profile  # ou execute este comando"
    else
        echo "⚠️  Nenhuma chave encontrada"
    fi
    
    return 0
}

mcp_keys_export() {
    echo "# Adicione ao seu ~/.bashrc ou ~/.zshrc:"
    echo ""
    [ -n "$CONTEXT7_API_KEY" ] && echo "export CONTEXT7_API_KEY=\"$CONTEXT7_API_KEY\""
    [ -n "$BASIC_MEMORY_API_KEY" ] && echo "export BASIC_MEMORY_API_KEY=\"$BASIC_MEMORY_API_KEY\""
    [ -n "$SERENA_API_KEY" ] && echo "export SERENA_API_KEY=\"$SERENA_API_KEY\""
}

# Se executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    mcp_keys_import "$@"
fi
