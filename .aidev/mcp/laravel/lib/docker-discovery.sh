#!/usr/bin/env bash
#
# Docker Discovery Service for Laravel Containers
# Detecta containers Docker rodando Laravel automaticamente
#

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Diretórios
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MCP_DIR="$(dirname "$SCRIPT_DIR")"
readonly STATE_DIR="$MCP_DIR/state"

# Arquivos de estado
readonly CONTAINERS_STATE="$STATE_DIR/containers.json"

# Criar diretório de estado se não existir
mkdir -p "$STATE_DIR"

# ============================================
# Funções de Utilidade
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
# Detecção de Docker
# ============================================

check_docker_available() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado ou não está no PATH"
        return 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon não está rodando ou usuário sem permissões"
        return 1
    fi

    return 0
}

# ============================================
# Detecção de Containers Laravel
# ============================================

is_laravel_container() {
    local container_name="$1"
    local container_image="$2"
    
    # Verificar por labels específicos do aidev
    local labels
    labels=$(docker inspect --format='{{json .Config.Labels}}' "$container_name" 2>/dev/null || echo '{}')
    
    if echo "$labels" | grep -q '"aidev.laravel.enabled":"true"' 2>/dev/null; then
        return 0
    fi
    
    # Verificar por imagens comuns de PHP/Laravel
    local php_images="php|laravel|octane|php-fpm|apache.*php|nginx.*php"
    if echo "$container_image" | grep -qiE "$php_images"; then
        return 0
    fi
    
    # Verificar por comandos Laravel dentro do container
    if docker exec "$container_name" sh -c 'test -f artisan && test -f composer.json' 2>/dev/null; then
        return 0
    fi
    
    return 1
}

detect_php_version() {
    local container_name="$1"
    local php_version
    
    php_version=$(docker exec "$container_name" sh -c 'php -v 2>/dev/null | head -1 | grep -oP "PHP \K[0-9]+\.[0-9]+"' || echo "unknown")
    
    echo "$php_version"
}

detect_laravel_version() {
    local container_name="$1"
    local laravel_version
    
    laravel_version=$(docker exec "$container_name" sh -c 'php artisan --version 2>/dev/null | grep -oP "Laravel Framework \K[0-9]+\.[0-9]+"' || echo "unknown")
    
    echo "$laravel_version"
}

get_container_info() {
    local container_id="$1"
    
    # Extrair informações básicas
    local name image status ip ports project_path
    
    name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/\///')
    image=$(docker inspect --format='{{.Config.Image}}' "$container_id")
    status=$(docker inspect --format='{{.State.Status}}' "$container_id")
    
    # Tentar obter IP (pode variar por network)
    ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id" 2>/dev/null || echo "")
    
    # Obter portas mapeadas
    ports=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{range $conf}}{{.HostIp}}:{{.HostPort}}->{{$p}} {{end}}{{end}}{{end}}' "$container_id" 2>/dev/null | sed 's/0\.0\.0\.0://g' || echo "")
    
    # Tentar descobrir path do projeto dentro do container
    project_path=$(docker exec "$name" sh -c 'pwd 2>/dev/null || echo "/var/www/html"' 2>/dev/null || echo "/var/www/html")
    
    # Criar objeto JSON
    cat <<EOF
{
  "id": "$container_id",
  "name": "$name",
  "image": "$image",
  "status": "$status",
  "ip": "$ip",
  "ports": "$ports",
  "project_path": "$project_path",
  "detected_at": "$(date -Iseconds)"
}
EOF
}

# ============================================
# Funções Principais
# ============================================

discover_all_containers() {
    log_info "Iniciando descoberta de containers..."
    
    if ! check_docker_available; then
        return 1
    fi
    
    local containers_json="["
    local first=true
    
    # Listar todos containers rodando
    while IFS= read -r container_id; do
        [ -z "$container_id" ] && continue
        
        local name image
        name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/\///')
        image=$(docker inspect --format='{{.Config.Image}}' "$container_id")
        
        log_info "Verificando container: $name ($image)"
        
        if is_laravel_container "$name" "$image"; then
            log_success "Container Laravel detectado: $name"
            
            local container_info
            container_info=$(get_container_info "$container_id")
            
            # Adicionar versões
            local php_version laravel_version
            php_version=$(detect_php_version "$name")
            laravel_version=$(detect_laravel_version "$name")
            
            # Merge com versões
            container_info=$(echo "$container_info" | jq --arg pv "$php_version" --arg lv "$laravel_version" '. + {php_version: $pv, laravel_version: $lv}')
            
            if [ "$first" = true ]; then
                first=false
            else
                containers_json+=","
            fi
            
            containers_json+="$container_info"
        fi
        
    done < <(docker ps -q)
    
    containers_json+="]"
    
    # Salvar estado
    echo "$containers_json" | jq '.' > "$CONTAINERS_STATE"
    
    local count
    count=$(echo "$containers_json" | jq 'length')
    
    log_success "Descoberta completa. $count container(s) Laravel encontrado(s)."
    echo "$containers_json"
}

get_container_by_name() {
    local container_name="$1"
    
    if [ ! -f "$CONTAINERS_STATE" ]; then
        discover_all_containers > /dev/null
    fi
    
    jq --arg name "$container_name" '.[] | select(.name == $name)' "$CONTAINERS_STATE"
}

list_containers() {
    if [ ! -f "$CONTAINERS_STATE" ]; then
        discover_all_containers
        return 0
    fi
    
    log_info "Containers Laravel detectados:"
    echo ""
    
    jq -r '.[] | "  \(.name) | PHP \(.php_version) | Laravel \(.laravel_version) | \(.status) | \(.project_path)"' "$CONTAINERS_STATE" 2>/dev/null || echo "  Nenhum container encontrado"
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  discover              Detecta todos containers Laravel (padrão)
  list                  Lista containers detectados
  get <name>            Retorna info de container específico
  watch                 Monitora novos containers (loop)
  help                  Mostra esta ajuda

Opções:
  -v, --verbose         Modo verbose
  -f, --force           Força redescoberta

Exemplos:
  $0 discover
  $0 list
  $0 get my-app-php
  $0 watch

EOF
}

main() {
    local command="${1:-discover}"
    
    case "$command" in
        discover)
            discover_all_containers
            ;;
        list)
            list_containers
            ;;
        get)
            if [ -z "${2:-}" ]; then
                log_error "Nome do container não especificado"
                echo "Uso: $0 get <container-name>"
                exit 1
            fi
            get_container_by_name "$2"
            ;;
        watch)
            log_info "Iniciando modo watch (Ctrl+C para sair)..."
            while true; do
                discover_all_containers > /dev/null
                sleep 5
            done
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
