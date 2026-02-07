#!/usr/bin/env bash
#
# Laravel Health Check
# Valida se um container Laravel está pronto para uso
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Status possíveis
readonly STATUS_HEALTHY="HEALTHY"
readonly STATUS_PENDING="PENDING"
readonly STATUS_FAILED="FAILED"

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
# Verificações de Health
# ============================================

check_container_running() {
    local container_name="$1"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Container não está rodando"
        return 1
    fi
    
    return 0
}

check_vendor_exists() {
    local container_name="$1"
    
    if docker exec "$container_name" test -d vendor 2>/dev/null; then
        return 0
    fi
    
    echo "Diretório vendor/ não encontrado (composer install pendente?)"
    return 1
}

check_env_file() {
    local container_name="$1"
    
    if docker exec "$container_name" test -f .env 2>/dev/null; then
        return 0
    fi
    
    echo "Arquivo .env não encontrado"
    return 1
}

check_artisan_working() {
    local container_name="$1"
    
    local artisan_output
    artisan_output=$(docker exec "$container_name" php artisan --version 2>&1) || {
        echo "Artisan não está respondendo: $artisan_output"
        return 1
    }
    
    if echo "$artisan_output" | grep -q "Laravel Framework"; then
        return 0
    fi
    
    echo "Artisan retornou erro"
    return 1
}

check_database_connection() {
    local container_name="$1"
    
    # Verificar se há configuração de DB
    local has_db_config
    has_db_config=$(docker exec "$container_name" sh -c 'grep -q "DB_CONNECTION" .env 2>/dev/null && echo "yes" || echo "no"')
    
    if [ "$has_db_config" = "no" ]; then
        log_warn "Sem configuração de banco de dados detectada, pulando check de DB"
        return 0
    fi
    
    # Tentar conexão com DB
    local db_check
    db_check=$(docker exec "$container_name" php artisan db:monitor --timeout=5 2>&1) || {
        echo "Não foi possível conectar ao banco de dados"
        return 1
    }
    
    return 0
}

check_storage_permissions() {
    local container_name="$1"
    
    # Verificar se storage e bootstrap/cache são graváveis
    local storage_ok cache_ok
    
    storage_ok=$(docker exec "$container_name" sh -c 'test -w storage && test -w storage/logs && echo "yes" || echo "no"')
    cache_ok=$(docker exec "$container_name" sh -c 'test -w bootstrap/cache && echo "yes" || echo "no"')
    
    if [ "$storage_ok" = "no" ]; then
        echo "Diretório storage/ sem permissões de escrita"
        return 1
    fi
    
    if [ "$cache_ok" = "no" ]; then
        echo "Diretório bootstrap/cache/ sem permissões de escrita"
        return 1
    fi
    
    return 0
}

# ============================================
# Health Check Principal
# ============================================

run_health_check() {
    local container_name="$1"
    local timeout="${2:-60}"
    local verbose="${3:-false}"
    
    local start_time
    start_time=$(date +%s)
    
    local checks=(
        "check_container_running:Container rodando"
        "check_vendor_exists:Dependências instaladas"
        "check_env_file:Arquivo .env presente"
        "check_artisan_working:Artisan funcional"
        "check_storage_permissions:Permissões de storage"
        "check_database_connection:Conexão com banco"
    )
    
    local failed_checks=()
    local pending_checks=()
    
    [ "$verbose" = "true" ] && log_info "Iniciando health check em '$container_name' (timeout: ${timeout}s)"
    
    for check_def in "${checks[@]}"; do
        IFS=':' read -r check_func check_name <<< "$check_def"
        
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -ge "$timeout" ]; then
            [ "$verbose" = "true" ] && log_warn "Timeout atingido"
            break
        fi
        
        [ "$verbose" = "true" ] && echo -n "  - $check_name... "
        
        local error_msg
        if error_msg=$($check_func "$container_name" 2>&1); then
            [ "$verbose" = "true" ] && log_success "OK"
        else
            [ "$verbose" = "true" ] && log_error "FALHOU"
            failed_checks+=("$check_name: $error_msg")
        fi
    done
    
    # Determinar status
    local status
    local message
    
    if [ ${#failed_checks[@]} -eq 0 ]; then
        status="$STATUS_HEALTHY"
        message="Todos os checks passaram"
        [ "$verbose" = "true" ] && log_success "Health check concluído: $status"
    elif [ ${#failed_checks[@]} -le 2 ]; then
        status="$STATUS_PENDING"
        message="Alguns checks pendentes: ${failed_checks[*]}"
        [ "$verbose" = "true" ] && log_warn "Health check concluído: $status"
    else
        status="$STATUS_FAILED"
        message="Múltiplos checks falharam: ${failed_checks[*]}"
        [ "$verbose" = "true" ] && log_error "Health check concluído: $status"
    fi
    
    # Retornar resultado como JSON
    cat <<EOF
{
  "container": "$container_name",
  "status": "$status",
  "timestamp": "$(date -Iseconds)",
  "elapsed_seconds": $(($(date +%s) - start_time)),
  "message": "$message",
  "failed_checks": $(printf '%s\n' "${failed_checks[@]}" | jq -R . | jq -s .),
  "is_healthy": $( [ "$status" = "$STATUS_HEALTHY" ] && echo "true" || echo "false" ),
  "is_pending": $( [ "$status" = "$STATUS_PENDING" ] && echo "true" || echo "false" ),
  "is_failed": $( [ "$status" = "$STATUS_FAILED" ] && echo "true" || echo "false" )
}
EOF
}

wait_for_healthy() {
    local container_name="$1"
    local max_wait="${2:-300}"  # 5 minutos padrão
    local interval="${3:-5}"    # checar a cada 5 segundos
    
    log_info "Aguardando container '$container_name' ficar saudável (max: ${max_wait}s)..."
    
    local start_time
    start_time=$(date +%s)
    
    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -ge "$max_wait" ]; then
            log_error "Timeout após ${max_wait}s aguardando container ficar saudável"
            return 1
        fi
        
        local result
        result=$(run_health_check "$container_name" 30 false)
        
        local status
        status=$(echo "$result" | jq -r '.status')
        
        if [ "$status" = "$STATUS_HEALTHY" ]; then
            log_success "Container está saudável após ${elapsed}s"
            echo "$result"
            return 0
        fi
        
        echo -n "."
        sleep "$interval"
    done
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  check <container>     Executa health check no container
  wait <container>      Aguarda container ficar saudável
  status <container>    Mostra status atual apenas

Opções:
  -t, --timeout <sec>   Timeout em segundos (padrão: 60)
  -i, --interval <sec>  Intervalo entre checks (padrão: 5)
  -v, --verbose         Modo verbose
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 check my-app-php
  $0 check my-app-php --timeout 120 --verbose
  $0 wait my-app-php --timeout 300
  $0 status my-app-php

EOF
}

main() {
    local command="${1:-}"
    shift || true
    
    local container_name=""
    local timeout=60
    local interval=5
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            -i|--interval)
                interval="$2"
                shift 2
                ;;
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
        check)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            run_health_check "$container_name" "$timeout" "$verbose"
            ;;
        wait)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            wait_for_healthy "$container_name" "$timeout" "$interval"
            ;;
        status)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            local result
            result=$(run_health_check "$container_name" 10 false)
            echo "$result" | jq -r '.status'
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
