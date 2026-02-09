#!/usr/bin/env bash
#
# Artisan Path Detector
# Detecta automaticamente o caminho do artisan no container Docker
#

set -euo pipefail

# Cores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ============================================
# Logging
# ============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# ============================================
# Detecção de Artisan Path
# ============================================

detect_artisan_path() {
    local container_name="$1"
    local detected_path=""
    
    log_info "Detectando caminho do artisan no container '$container_name'..."
    
    # Estratégia 1: Caminhos padrão conhecidos
    local common_paths=(
        "/var/www/html/artisan"      # Laravel Sail (mais comum)
        "/var/www/artisan"           # Alternativo
        "/app/artisan"               # Docker genérico
        "/srv/artisan"               # Outro padrão
        "/home/www/artisan"          # Setup custom
        "/opt/artisan"               # Instalação opt
        "/code/artisan"              # VSCode dev containers
        "/workspace/artisan"         # Gitpod/Codespaces
        "/var/www/app/artisan"       # Estrutura alternativa
        "/usr/share/nginx/html/artisan"  # Nginx padrão
        "/var/www/public_html/artisan"   # cPanel/WHM
        "/home/laravel/artisan"      # Usuário específico
    )
    
    for path in "${common_paths[@]}"; do
        if docker exec "$container_name" test -f "$path" 2>/dev/null; then
            # Verifica se é realmente o artisan do Laravel
            if docker exec "$container_name" head -1 "$path" 2>/dev/null | grep -q "php\|artisan"; then
                detected_path="$path"
                log_success "✓ Encontrado em caminho padrão: $path"
                break
            fi
        fi
    done
    
    # Estratégia 2: Busca recursiva em /var/www (rápida)
    if [ -z "$detected_path" ]; then
        log_info "Buscando recursivamente em /var/www..."
        detected_path=$(docker exec "$container_name" find /var/www -name artisan -type f 2>/dev/null | head -1)
        
        if [ -n "$detected_path" ]; then
            log_success "✓ Encontrado via busca: $detected_path"
        fi
    fi
    
    # Estratégia 3: Busca em /app (comum em containers modernos)
    if [ -z "$detected_path" ]; then
        log_info "Buscando em /app..."
        detected_path=$(docker exec "$container_name" find /app -name artisan -type f 2>/dev/null | head -1)
        
        if [ -n "$detected_path" ]; then
            log_success "✓ Encontrado em /app: $detected_path"
        fi
    fi
    
    # Estratégia 4: Busca em todo o sistema (mais lenta, só se necessário)
    if [ -z "$detected_path" ]; then
        log_info "Buscando em todo o container (isso pode levar alguns segundos)..."
        # Exclui diretórios do sistema que não fazem sentido
        detected_path=$(docker exec "$container_name" sh -c 'find / -name artisan -type f 2>/dev/null | grep -v "^/proc\|^/sys\|^/dev\|^/bin\|^/sbin\|^/lib\|^/usr/share" | head -1' 2>/dev/null)
        
        if [ -n "$detected_path" ]; then
            log_success "✓ Encontrado em: $detected_path"
        fi
    fi
    
    # Validação final
    if [ -n "$detected_path" ]; then
        # Testa se funciona
        if docker exec "$container_name" php "$detected_path" --version &>/dev/null; then
            log_success "✓ Validado: $detected_path funciona!"
            echo "$detected_path"
            return 0
        else
            log_warn "⚠ Encontrado mas não funcionou: $detected_path"
        fi
    fi
    
    # Fallback
    log_warn "⚠ Usando fallback: /var/www/html/artisan"
    echo "/var/www/html/artisan"
    return 1
}

# ============================================
# Detecção do Comando Boost
# ============================================

detect_boost_command() {
    local container_name="$1"
    local artisan_path="${2:-/var/www/html/artisan}"
    
    log_info "Detectando comando Boost disponível..."
    
    # Lista de comandos possíveis em ordem de prioridade
    local possible_commands=(
        "boost:mcp"
        "mcp:serve"
        "mcp:start laravel-boost"
        "boost:serve"
    )
    
    for cmd in "${possible_commands[@]}"; do
        local cmd_name="${cmd%% *}"  # Pega primeira parte (antes do espaço)
        
        if docker exec "$container_name" php "$artisan_path" list 2>/dev/null | grep -q "$cmd_name"; then
            log_success "✓ Comando encontrado: $cmd"
            echo "$cmd"
            return 0
        fi
    done
    
    # Fallback padrão
    log_warn "⚠ Comando Boost não detectado, usando fallback: boost:mcp"
    echo "boost:mcp"
    return 1
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [CONTAINER]

Comandos:
  detect <container>     Detecta caminho do artisan
  command <container>    Detecta comando Boost disponível

Exemplos:
  $0 detect spadaer-laravel.test-1
  $0 command spadaer-laravel.test-1

EOF
}

main() {
    local command="${1:-help}"
    local container_name="${2:-}"
    
    case "$command" in
        detect|path)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            detect_artisan_path "$container_name"
            ;;
        command|cmd|boost)
            if [ -z "$container_name" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            local artisan_path
            artisan_path=$(detect_artisan_path "$container_name")
            detect_boost_command "$container_name" "$artisan_path"
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
