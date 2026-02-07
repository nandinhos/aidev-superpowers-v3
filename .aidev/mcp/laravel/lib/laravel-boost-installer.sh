#!/usr/bin/env bash
#
# Laravel Boost Auto-Installer
# Verifica se Laravel está pronto para MCP (versão simplificada)
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_DIR="$(dirname "$SCRIPT_DIR")"
readonly STATE_DIR="$MCP_DIR/state"
readonly LOG_FILE="$STATE_DIR/boost-installer.log"

# Configurações
readonly COMPOSER_TIMEOUT=300  # 5 minutos

# ============================================
# Logging
# ============================================

ensure_state() {
    mkdir -p "$STATE_DIR"
    touch "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ============================================
# Detecção de Laravel Boost
# ============================================

check_laravel_boost_installed() {
    local container_name="$1"
    
    # Verificar se Laravel está funcional
    if docker exec "$container_name" php artisan --version &>/dev/null; then
        echo "installed"
    else
        echo "not_installed"
    fi
}

check_composer_available() {
    local container_name="$1"
    
    if docker exec "$container_name" which composer > /dev/null 2>&1; then
        echo "yes"
    elif docker exec "$container_name" test -f /usr/local/bin/composer; then
        echo "yes"
    else
        echo "no"
    fi
}

# ============================================
# Instalação
# ============================================

install_laravel_boost() {
    local container_name="$1"
    local version_constraint="${2:-^1.0}"
    
    log_info "[$container_name] Iniciando instalação do Laravel Boost..."
    
    # Verificar composer
    if [ "$(check_composer_available "$container_name")" = "no" ]; then
        log_error "[$container_name] Composer não encontrado no container"
        return 1
    fi
    
    # Determinar versão do Laravel
    local laravel_version
    laravel_version=$(docker exec "$container_name" php artisan --version 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
    
    log_info "[$container_name] Laravel version detectada: $laravel_version"
    
    # Escolher package correto baseado na versão
    local package_name
    if [ "${laravel_version%%.*}" -ge 11 ] 2>/dev/null; then
        package_name="$LARAVEL_BOOST_PACKAGE"
        version_constraint="^2.0"
    elif [ "${laravel_version%%.*}" -ge 10 ] 2>/dev/null; then
        package_name="$LARAVEL_BOOST_PACKAGE"
        version_constraint="^1.0"
    else
        package_name="$LARAVEL_BOOST_PACKAGE_DEV"
        version_constraint="*"
    fi
    
    log_info "[$container_name] Instalando $package_name:$version_constraint..."
    
    # Instalar via composer
    local install_output
    if ! install_output=$(docker exec "$container_name" composer require "$package_name:$version_constraint" --no-interaction --quiet 2>&1); then
        log_error "[$container_name] Falha na instalação: $install_output"
        return 1
    fi
    
    log_success "[$container_name] Package instalado com sucesso"
    
    # Publicar configurações
    log_info "[$container_name] Publicando configurações..."
    docker exec "$container_name" php artisan vendor:publish --provider="Laravel\Mcp\McpServiceProvider" --tag="config" --quiet 2>/dev/null || true
    
    # Limpar cache
    log_info "[$container_name] Limpando cache..."
    docker exec "$container_name" php artisan config:clear --quiet 2>/dev/null || true
    docker exec "$container_name" php artisan cache:clear --quiet 2>/dev/null || true
    
    return 0
}

install_composer_if_needed() {
    local container_name="$1"
    
    log_info "[$container_name] Verificando composer..."
    
    if [ "$(check_composer_available "$container_name")" = "yes" ]; then
        log_info "[$container_name] Composer já disponível"
        return 0
    fi
    
    log_warn "[$container_name] Composer não encontrado, tentando instalar..."
    
    # Baixar composer
    local install_script
    install_script=$(docker exec "$container_name" sh -c 'php -r "copy('\''https://getcomposer.org/installer'\'', '\''composer-setup.php'\'');"' 2>&1)
    
    if ! docker exec "$container_name" test -f composer-setup.php; then
        log_error "[$container_name] Não foi possível baixar composer"
        return 1
    fi
    
    # Instalar
    docker exec "$container_name" php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet 2>/dev/null || {
        log_error "[$container_name] Falha ao instalar composer"
        docker exec "$container_name" rm -f composer-setup.php 2>/dev/null || true
        return 1
    }
    
    # Limpar
    docker exec "$container_name" rm -f composer-setup.php 2>/dev/null || true
    
    log_success "[$container_name] Composer instalado"
    return 0
}

# ============================================
# Configuração Pós-Instalação
# ============================================

configure_laravel_boost() {
    local container_name="$1"
    
    log_info "[$container_name] Configurando Laravel Boost..."
    
    # Verificar se existe arquivo de config
    local config_exists
    config_exists=$(docker exec "$container_name" test -f config/mcp.php 2>/dev/null && echo "yes" || echo "no")
    
    if [ "$config_exists" = "no" ]; then
        log_warn "[$container_name] Arquivo de config não encontrado, tentando publicar novamente..."
        docker exec "$container_name" php artisan vendor:publish --tag="mcp-config" --force --quiet 2>/dev/null || true
    fi
    
    # Verificar permissões de storage
    log_info "[$container_name] Verificando permissões..."
    docker exec "$container_name" chmod -R 775 storage bootstrap/cache 2>/dev/null || true
    docker exec "$container_name" chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true
    
    log_success "[$container_name] Configuração completa"
}

# ============================================
# Instalação Completa
# ============================================

bootstrap_container() {
    local container_name="$1"
    local force="${2:-false}"
    
    ensure_state
    
    log_info "=========================================="
    log_info "Bootstrap Laravel: $container_name"
    log_info "=========================================="
    
    # Passo 1: Verificar se Laravel está pronto
    log_info "[$container_name] Verificando Laravel..."
    
    if ! docker exec "$container_name" test -f artisan 2>/dev/null; then
        log_error "[$container_name] artisan não encontrado no container"
        return 1
    fi
    
    if ! docker exec "$container_name" test -d vendor 2>/dev/null; then
        log_error "[$container_name] vendor/ não encontrado. Execute 'composer install' primeiro"
        return 1
    fi
    
    # Verificar versão do Laravel
    local laravel_version
    laravel_version=$(docker exec "$container_name" php artisan --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    log_success "[$container_name] Laravel $laravel_version detectado"
    
    # Passo 2: Ajustar permissões (se necessário)
    log_info "[$container_name] Verificando permissões..."
    docker exec "$container_name" chmod -R 775 storage bootstrap/cache 2>/dev/null || true
    
    log_success "=========================================="
    log_success "[$container_name] Laravel pronto para MCP!"
    log_success "=========================================="
    return 0
}

# ============================================
# CLI
# ============================================

show_status() {
    local container_name="$1"
    
    ensure_state
    
    local status
    status=$(check_laravel_boost_installed "$container_name")
    
    local icon="❓"
    case "$status" in
        "installed") icon="✅" ;;
        "partial") icon="⚠️" ;;
        "needs_provider") icon="⚙️" ;;
        "not_installed") icon="❌" ;;
    esac
    
    echo "$icon $container_name: $status"
    
    # Detalhes adicionais
    if [ "$status" != "not_installed" ]; then
        local version
        version=$(docker exec "$container_name" php artisan --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        echo "   Laravel: $version"
        
        local has_composer
        has_composer=$(check_composer_available "$container_name")
        echo "   Composer: $has_composer"
    fi
}

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  install <container>   Instala Laravel Boost no container
  status <container>    Mostra status de instalação
  check <container>     Verifica se está instalado (exit 0/1)
  configure <container> Configura Laravel Boost (pós-instalação)
  logs                  Mostra logs de instalação

Opções:
  -f, --force           Força reinstalação
  -v, --version         Versão específica do package
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 install my-app-php              Instala no container
  $0 install my-app-php --force      Força reinstalação
  $0 status my-app-php               Mostra status
  $0 check my-app-php                Verifica instalação (exit code)

EOF
}

main() {
    local command="${1:-help}"
    shift || true
    
    local container_name=""
    local force=false
    local version_constraint=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--force)
                force=true
                shift
                ;;
            -v|--version)
                version_constraint="$2"
                shift 2
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
        install|bootstrap)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            bootstrap_container "$container_name" "$force"
            ;;
        status|info)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            show_status "$container_name"
            ;;
        check|verify)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            local status
            status=$(check_laravel_boost_installed "$container_name")
            if [ "$status" = "installed" ]; then
                echo "installed"
                exit 0
            else
                echo "$status"
                exit 1
            fi
            ;;
        configure|setup)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            ensure_state
            configure_laravel_boost "$container_name"
            ;;
        logs|log)
            ensure_state
            if [ -f "$LOG_FILE" ]; then
                tail -n 50 "$LOG_FILE"
            else
                echo "Nenhum log encontrado"
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
