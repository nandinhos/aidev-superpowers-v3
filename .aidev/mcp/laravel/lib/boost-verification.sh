#!/usr/bin/env bash
#
# Laravel Boost Verification
# Valida que Laravel Boost está operacional após instalação
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
readonly STATE_DIR="$MCP_DIR/state"

# Status possíveis
readonly STATUS_OK="OK"
readonly STATUS_WARNING="WARNING"
readonly STATUS_ERROR="ERROR"

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
# Verificações de Componentes
# ============================================

check_package_installed() {
    local container_name="$1"
    
    log_info "Verificando se package está instalado..."
    
    local has_mcp
    has_mcp=$(docker exec "$container_name" sh -c 'cat composer.json 2>/dev/null | grep -q "mcp" && echo "yes" || echo "no"')
    
    if [ "$has_mcp" = "yes" ]; then
        log_success "Package MCP encontrado no composer.json"
        return 0
    else
        log_error "Package MCP não encontrado"
        return 1
    fi
}

check_service_provider() {
    local container_name="$1"
    
    log_info "Verificando Service Provider..."
    
    # Tentar listar providers via artisan
    local providers_output
    providers_output=$(docker exec "$container_name" php artisan package:discover --quiet 2>&1 || echo "")
    
    if echo "$providers_output" | grep -qi "mcp"; then
        log_success "Service Provider MCP detectado"
        return 0
    fi
    
    # Verificar se comandos MCP estão disponíveis
    local commands_output
    commands_output=$(docker exec "$container_name" php artisan list 2>/dev/null || echo "")
    
    if echo "$commands_output" | grep -q "mcp"; then
        log_success "Comandos MCP disponíveis"
        return 0
    fi
    
    log_error "Service Provider MCP não detectado"
    return 1
}

check_mcp_commands() {
    local container_name="$1"
    
    log_info "Verificando comandos MCP..."
    
    local commands
    commands=$(docker exec "$container_name" php artisan list 2>/dev/null | grep -i "mcp" || echo "")
    
    if [ -z "$commands" ]; then
        log_error "Nenhum comando MCP encontrado"
        return 1
    fi
    
    log_success "Comandos MCP encontrados:"
    echo "$commands" | while read -r cmd; do
        echo "  - $cmd"
    done
    
    return 0
}

check_mcp_config() {
    local container_name="$1"
    
    log_info "Verificando configuração MCP..."
    
    local config_exists
    config_exists=$(docker exec "$container_name" test -f config/mcp.php 2>/dev/null && echo "yes" || echo "no")
    
    if [ "$config_exists" = "yes" ]; then
        log_success "Arquivo de configuração encontrado"
        
        # Verificar conteúdo básico
        local config_valid
        config_valid=$(docker exec "$container_name" sh -c 'grep -q "servers" config/mcp.php 2>/dev/null && echo "yes" || echo "no"')
        
        if [ "$config_valid" = "yes" ]; then
            log_success "Configuração parece válida"
        else
            log_warn "Configuração pode estar incompleta"
        fi
        
        return 0
    else
        log_warn "Arquivo de configuração não encontrado (pode ser opcional)"
        return 0  # Não é erro fatal
    fi
}

check_mcp_server_command() {
    local container_name="$1"
    
    log_info "Testando comando mcp:serve..."
    
    # Testar se o comando existe
    local help_output
    help_output=$(docker exec "$container_name" php artisan mcp:serve --help 2>&1 || echo "")
    
    if [ -n "$help_output" ] && ! echo "$help_output" | grep -q "not found\|does not exist"; then
        log_success "Comando mcp:serve disponível"
        
        # Extrair opções
        local options
        options=$(echo "$help_output" | grep -E "^\s+--" | head -5 || echo "")
        
        if [ -n "$options" ]; then
            echo "  Opções disponíveis:"
            echo "$options" | while read -r opt; do
                echo "    $opt"
            done
        fi
        
        return 0
    else
        log_error "Comando mcp:serve não disponível"
        return 1
    fi
}

check_mcp_endpoints() {
    local container_name="$1"
    
    log_info "Verificando endpoints MCP (se aplicável)..."
    
    # Verificar se há rotas MCP registradas
    local routes_output
    routes_output=$(docker exec "$container_name" php artisan route:list 2>/dev/null | grep -i "mcp" || echo "")
    
    if [ -n "$routes_output" ]; then
        log_success "Rotas MCP encontradas:"
        echo "$routes_output" | head -5 | while read -r route; do
            echo "  $route"
        done
    else
        log_info "Nenhuma rota MCP específica encontrada (pode ser normal)"
    fi
    
    return 0
}

check_storage_permissions() {
    local container_name="$1"
    
    log_info "Verificando permissões de storage..."
    
    local storage_ok cache_ok
    
    storage_ok=$(docker exec "$container_name" sh -c 'test -w storage/logs && echo "yes" || echo "no"' 2>/dev/null)
    cache_ok=$(docker exec "$container_name" sh -c 'test -w bootstrap/cache && echo "yes" || echo "no"' 2>/dev/null)
    
    if [ "$storage_ok" = "yes" ] && [ "$cache_ok" = "yes" ]; then
        log_success "Permissões corretas"
        return 0
    else
        log_warn "Permissões podem estar incorretas"
        [ "$storage_ok" != "yes" ] && log_warn "  storage/logs não tem permissão de escrita"
        [ "$cache_ok" != "yes" ] && log_warn "  bootstrap/cache não tem permissão de escrita"
        return 0  # Warning, não erro
    fi
}

check_mcp_integration() {
    local container_name="$1"
    
    log_info "Testando integração MCP..."
    
    # Tentar executar um comando simples do MCP
    local test_output
    test_output=$(docker exec "$container_name" timeout 5 php artisan mcp:ping 2>&1 || echo "")
    
    if echo "$test_output" | grep -q "pong\|success\|ok"; then
        log_success "Integração MCP funcionando"
        return 0
    fi
    
    # Se não tem mcp:ping, tentar info
    test_output=$(docker exec "$container_name" timeout 5 php artisan mcp:info 2>&1 || echo "")
    
    if [ -n "$test_output" ] && ! echo "$test_output" | grep -q "not found"; then
        log_success "Comando mcp:info respondeu"
        return 0
    fi
    
    log_warn "Não foi possível verificar integração (pode ser normal)"
    return 0
}

# ============================================
# Verificação Completa
# ============================================

run_full_verification() {
    local container_name="$1"
    local verbose="${2:-false}"
    
    log_info "=========================================="
    log_info "Verificação Laravel Boost: $container_name"
    log_info "=========================================="
    
    local passed=0
    local failed=0
    local warnings=0
    
    local checks=(
        "check_package_installed:Package Instalado:2"
        "check_service_provider:Service Provider:2"
        "check_mcp_commands:Comandos MCP:1"
        "check_mcp_config:Configuração:1"
        "check_mcp_server_command:Comando mcp:serve:2"
        "check_mcp_endpoints:Endpoints:0"
        "check_storage_permissions:Permissões:0"
        "check_mcp_integration:Integração:1"
    )
    
    for check_def in "${checks[@]}"; do
        IFS=':' read -r check_func check_name weight <<< "$check_def"
        
        [ "$verbose" = "true" ] && echo ""
        
        if $check_func "$container_name"; then
            ((passed += weight))
        else
            if [ "$weight" -ge 2 ]; then
                ((failed++))
            else
                ((warnings++))
            fi
        fi
    done
    
    echo ""
    log_info "=========================================="
    log_info "Resumo da Verificação"
    log_info "=========================================="
    echo "  ✅ Passou: $passed pontos"
    [ "$warnings" -gt 0 ] && echo "  ⚠️  Avisos: $warnings"
    [ "$failed" -gt 0 ] && echo "  ❌ Falhas: $failed"
    
    # Determinar status geral
    local overall_status
    if [ "$failed" -eq 0 ]; then
        if [ "$warnings" -eq 0 ]; then
            overall_status="$STATUS_OK"
            log_success "Status: $overall_status"
        else
            overall_status="$STATUS_WARNING"
            log_warn "Status: $overall_status"
        fi
    else
        overall_status="$STATUS_ERROR"
        log_error "Status: $overall_status"
    fi
    
    # Retornar resultado como JSON
    cat <<EOF
{
  "container": "$container_name",
  "status": "$overall_status",
  "passed": $passed,
  "warnings": $warnings,
  "failed": $failed,
  "timestamp": "$(date -Iseconds)"
}
EOF
    
    if [ "$overall_status" = "$STATUS_ERROR" ]; then
        return 1
    else
        return 0
    fi
}

quick_check() {
    local container_name="$1"
    
    # Verificação rápida para automação
    local has_mcp has_commands
    
    has_mcp=$(docker exec "$container_name" sh -c 'cat composer.json 2>/dev/null | grep -q "mcp" && echo "yes" || echo "no"')
    
    if [ "$has_mcp" != "yes" ]; then
        echo "not_installed"
        return 1
    fi
    
    has_commands=$(docker exec "$container_name" php artisan list 2>/dev/null | grep -q "mcp:serve" && echo "yes" || echo "no")
    
    if [ "$has_commands" = "yes" ]; then
        echo "ready"
        return 0
    else
        echo "partial"
        return 1
    fi
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  verify <container>    Verificação completa do Laravel Boost
  quick <container>     Verificação rápida (exit 0/1)
  test <container>      Testa integração MCP
  diagnostics <container> Mostra diagnósticos detalhados

Opções:
  -v, --verbose         Modo verbose
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 verify my-app-php           Verificação completa
  $0 verify my-app-php --verbose Verbose
  $0 quick my-app-php            Check rápido (automação)
  $0 test my-app-php             Testa integração

EOF
}

main() {
    local command="${1:-help}"
    shift || true
    
    local container_name=""
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$container_name" ]; then
                    container_name="$1"
                fi
                shift
                ;;
        esac
    done
    
    case "$command" in
        verify|check)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            run_full_verification "$container_name" "$verbose"
            ;;
        quick|status)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            local status
            status=$(quick_check "$container_name")
            echo "$status"
            if [ "$status" = "ready" ]; then
                exit 0
            else
                exit 1
            fi
            ;;
        test|integration)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            check_mcp_integration "$container_name"
            ;;
        diagnostics|diag)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            verbose=true
            run_full_verification "$container_name" "$verbose"
            
            echo ""
            log_info "Diagnósticos adicionais:"
            
            # Versões
            echo ""
            echo "Versões:"
            docker exec "$container_name" php --version 2>/dev/null | head -1
            docker exec "$container_name" php artisan --version 2>/dev/null
            docker exec "$container_name" composer --version 2>/dev/null | head -1
            
            # Dependências
            echo ""
            echo "Dependências MCP:"
            docker exec "$container_name" sh -c 'cat composer.json | grep -A5 "require" | grep "mcp"' 2>/dev/null || echo "  Nenhuma encontrada"
            
            # Config
            echo ""
            echo "Arquivos de config:"
            docker exec "$container_name" ls -la config/mcp.php 2>/dev/null || echo "  config/mcp.php não existe"
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
