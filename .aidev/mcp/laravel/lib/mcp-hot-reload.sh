#!/usr/bin/env bash
#
# MCP Hot Reload
# Aplica nova configuração MCP sem reiniciar IDE/Editor
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_DIR="$(dirname "$SCRIPT_DIR")"
readonly CONFIG_DIR="$MCP_DIR/config"
readonly BACKUP_DIR="$MCP_DIR/backups"

# Arquivo de configuração MCP unificado
readonly MCP_CONFIG_FILE="$CONFIG_DIR/mcp-servers.json"

# ============================================
# Logging
# ============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================
# Detectar MCP Client
# ============================================

detect_mcp_client() {
    # Detectar qual cliente MCP está sendo usado
    
    # Claude Desktop
    if [ -d "$HOME/Library/Application Support/Claude" ] || \
       [ -d "$HOME/.config/Claude" ]; then
        echo "claude-desktop"
        return 0
    fi
    
    # Cursor
    if [ -d "$HOME/.cursor" ] || \
       [ -d "$HOME/Library/Application Support/Cursor" ]; then
        echo "cursor"
        return 0
    fi
    
    # VSCode/Codium com MCP extension
    if [ -d "$HOME/.vscode" ] || [ -d "$HOME/.vscode-oss" ]; then
        echo "vscode"
        return 0
    fi
    
    echo "unknown"
}

get_mcp_config_path() {
    local client="$1"
    
    case "$client" in
        "claude-desktop")
            # macOS
            if [ -f "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ]; then
                echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
                return 0
            fi
            # Linux
            if [ -f "$HOME/.config/Claude/claude_desktop_config.json" ]; then
                echo "$HOME/.config/Claude/claude_desktop_config.json"
                return 0
            fi
            ;;
        "cursor")
            if [ -f "$HOME/.cursor/mcp.json" ]; then
                echo "$HOME/.cursor/mcp.json"
                return 0
            fi
            if [ -f "$HOME/Library/Application Support/Cursor/mcp.json" ]; then
                echo "$HOME/Library/Application Support/Cursor/mcp.json"
                return 0
            fi
            ;;
        "vscode")
            # VSCode MCP extension
            if [ -f "$HOME/.vscode/mcp.json" ]; then
                echo "$HOME/.vscode/mcp.json"
                return 0
            fi
            ;;
    esac
    
    echo ""
}

# ============================================
# Backup e Restore
# ============================================

backup_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        return 0
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    local backup_file
    backup_file="$BACKUP_DIR/$(basename "$config_file").$(date +%Y%m%d%H%M%S).bak"
    
    cp "$config_file" "$backup_file"
    log_info "Backup criado: $backup_file"
    
    echo "$backup_file"
}

restore_config() {
    local backup_file="$1"
    local target_file="$2"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup não encontrado: $backup_file"
        return 1
    fi
    
    cp "$backup_file" "$target_file"
    log_success "Configuração restaurada de: $backup_file"
}

# ============================================
# Merge de Configurações
# ============================================

merge_mcp_configs() {
    local target_file="$1"
    local new_config_file="$2"
    
    # Se não existe config alvo, apenas copiar
    if [ ! -f "$target_file" ]; then
        log_info "Criando nova configuração MCP..."
        cp "$new_config_file" "$target_file"
        return 0
    fi
    
    # Fazer backup
    backup_config "$target_file"
    
    # Merge usando jq
    log_info "Mesclando configurações MCP..."
    
    local merged
    merged=$(jq -s '.[0].mcpServers = (.[0].mcpServers // {}) + .[1].mcpServers | .[0]' "$target_file" "$new_config_file" 2>/dev/null)
    
    if [ -z "$merged" ]; then
        log_error "Falha ao mesclar configurações"
        return 1
    fi
    
    # Salvar resultado
    echo "$merged" | jq '.' > "$target_file"
    log_success "Configurações mescladas com sucesso"
}

# ============================================
# Validação
# ============================================

validate_mcp_config() {
    local config_file="$1"
    
    # Verificar se é JSON válido
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "Arquivo não é JSON válido: $config_file"
        return 1
    fi
    
    # Verificar estrutura mínima MCP
    if ! jq -e '.mcpServers' "$config_file" > /dev/null 2>&1; then
        log_error "Configuração não contém mcpServers"
        return 1
    fi
    
    # Verificar cada servidor
    local servers
    servers=$(jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null)
    
    for server in $servers; do
        # Verificar se tem command ou url
        if ! jq -e ".mcpServers[\"$server\"] | has(\"command\") or has(\"url\")" "$config_file" > /dev/null 2>&1; then
            log_warn "Servidor '$server' não tem 'command' ou 'url'"
        fi
    done
    
    return 0
}

# ============================================
# Hot Reload
# ============================================

hot_reload() {
    local config_file="${1:-$MCP_CONFIG_FILE}"
    
    log_info "Iniciando hot-reload..."
    
    # Validar config
    if ! validate_mcp_config "$config_file"; then
        log_error "Configuração inválida, abortando"
        return 1
    fi
    
    # Detectar cliente MCP
    local mcp_client
    mcp_client=$(detect_mcp_client)
    log_info "Cliente MCP detectado: $mcp_client"
    
    # Obter path da config do cliente
    local client_config_path
    client_config_path=$(get_mcp_config_path "$mcp_client")
    
    if [ -z "$client_config_path" ]; then
        log_warn "Não foi possível detectar path de config do cliente MCP"
        log_info "Salvando configuração em: $config_file"
        
        # Apenas validar e reportar
        if validate_mcp_config "$config_file"; then
            log_success "Configuração válida e pronta para uso manual"
            echo ""
            echo "Para aplicar manualmente:"
            echo "  Copie o conteúdo de: $config_file"
            echo "  Para a configuração do seu cliente MCP"
        fi
        return 0
    fi
    
    log_info "Path da config do cliente: $client_config_path"
    
    # Merge e aplicar
    if merge_mcp_configs "$client_config_path" "$config_file"; then
        log_success "Hot-reload aplicado com sucesso!"
        
        # Instruções específicas por cliente
        case "$mcp_client" in
            "claude-desktop")
                echo ""
                log_info "📝 Próximo passo:"
                echo "   Reinicie o Claude Desktop para aplicar as mudanças"
                echo "   Ou use Cmd/Ctrl + R para recarregar"
                ;;
            "cursor")
                echo ""
                log_info "📝 Próximo passo:"
                echo "   Reinicie o Cursor para aplicar as mudanças"
                ;;
            "vscode")
                echo ""
                log_info "📝 Próximo passo:"
                echo "   Recarregue a janela do VSCode (Cmd/Ctrl + Shift + P > Reload Window)"
                ;;
        esac
        
        return 0
    else
        log_error "Falha ao aplicar hot-reload"
        return 1
    fi
}

# ============================================
# Preview
# ============================================

preview_config() {
    local config_file="${1:-$MCP_CONFIG_FILE}"
    
    if [ ! -f "$config_file" ]; then
        log_error "Arquivo de config não encontrado: $config_file"
        return 1
    fi
    
    log_info "Preview da configuração:"
    echo "=========================================="
    jq '.' "$config_file"
    echo "=========================================="
    
    if validate_mcp_config "$config_file"; then
        log_success "Configuração válida"
    else
        log_error "Configuração inválida"
    fi
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  reload [file]         Aplica hot-reload da configuração
  preview [file]        Mostra preview da configuração
  validate [file]       Valida configuração MCP
  backup <file>         Cria backup de configuração
  restore <backup>      Restaura configuração de backup
  detect                Detecta cliente MCP instalado

Opções:
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 reload                           Aplica reload da config padrão
  $0 reload ./my-config.json          Aplica reload de arquivo específico
  $0 preview                          Mostra preview
  $0 validate                         Valida configuração
  $0 detect                           Detecta cliente MCP

EOF
}

main() {
    local command="${1:-help}"
    shift || true
    
    local config_file="${1:-$MCP_CONFIG_FILE}"
    
    # Criar diretórios necessários
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
    
    case "$command" in
        reload|apply|update)
            hot_reload "$config_file"
            ;;
        preview|show|view)
            preview_config "$config_file"
            ;;
        validate|check)
            if validate_mcp_config "$config_file"; then
                log_success "Configuração válida: $config_file"
                exit 0
            else
                log_error "Configuração inválida: $config_file"
                exit 1
            fi
            ;;
        backup)
            if [ -z "${1:-}" ]; then
                log_error "Arquivo não especificado"
                show_help
                exit 1
            fi
            backup_config "$1"
            ;;
        restore)
            if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
                log_error "Usage: $0 restore <backup-file> <target-file>"
                exit 1
            fi
            restore_config "$1" "$2"
            ;;
        detect|detect-client)
            local client
            client=$(detect_mcp_client)
            log_info "Cliente MCP detectado: $client"
            
            local config_path
            config_path=$(get_mcp_config_path "$client")
            if [ -n "$config_path" ]; then
                log_info "Config path: $config_path"
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Comando desconhecido: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
