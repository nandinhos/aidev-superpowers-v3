#!/usr/bin/env bash
#
# Docker Events Watcher
# Monitora eventos Docker para detectar containers Laravel iniciando
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
readonly EVENTS_LOG="$STATE_DIR/docker-events.log"

# Arquivo PID para controle do daemon
readonly PID_FILE="$STATE_DIR/events-watcher.pid"

# Debounce em segundos (evitar múltiplos triggers para mesmo container)
readonly DEBOUNCE_SECONDS=10

# ============================================
# Logging
# ============================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$EVENTS_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$EVENTS_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$EVENTS_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$EVENTS_LOG"
}

log_event() {
    echo -e "${CYAN}[EVENT]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$EVENTS_LOG"
}

# ============================================
# Controle do Daemon
# ============================================

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
    touch "$EVENTS_LOG"
}

is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

start_daemon() {
    ensure_state_dir
    
    if is_running; then
        log_warn "Watcher já está rodando (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    log_info "Iniciando Docker Events Watcher..."
    
    # Rodar em background
    (
        exec > >(tee -a "$EVENTS_LOG")
        exec 2>&1
        watch_docker_events
    ) &
    
    local pid=$!
    echo "$pid" > "$PID_FILE"
    
    log_success "Watcher iniciado (PID: $pid)"
    log_info "Logs em: $EVENTS_LOG"
}

stop_daemon() {
    if ! is_running; then
        log_warn "Watcher não está rodando"
        return 1
    fi
    
    local pid
    pid=$(cat "$PID_FILE")
    
    log_info "Parando Watcher (PID: $pid)..."
    
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    
    log_success "Watcher parado"
}

status_daemon() {
    if is_running; then
        log_success "Watcher está rodando (PID: $(cat "$PID_FILE"))"
        log_info "Log: $EVENTS_LOG"
        
        # Mostrar últimos eventos
        if [ -f "$EVENTS_LOG" ]; then
            echo ""
            echo "Últimos eventos:"
            tail -n 10 "$EVENTS_LOG"
        fi
    else
        log_warn "Watcher não está rodando"
    fi
}

# ============================================
# Debounce
# ============================================

# Registra último processamento para cada container
declare -A LAST_PROCESSED

should_process_container() {
    local container_name="$1"
    local now
    now=$(date +%s)
    
    local last_processed="${LAST_PROCESSED[$container_name]:-0}"
    local diff=$((now - last_processed))
    
    if [ "$diff" -lt "$DEBOUNCE_SECONDS" ]; then
        return 1  # Não processar (debounce)
    fi
    
    # Atualizar timestamp
    LAST_PROCESSED[$container_name]=$now
    return 0  # Processar
}

# ============================================
# Verificação de Container Laravel
# ============================================

is_laravel_container_by_id() {
    local container_id="$1"
    
    # Verificar labels
    local labels
    labels=$(docker inspect --format='{{json .Config.Labels}}' "$container_id" 2>/dev/null || echo '{}')
    
    if echo "$labels" | grep -q '"aidev.laravel.enabled":"true"' 2>/dev/null; then
        return 0
    fi
    
    # Verificar imagem
    local image
    image=$(docker inspect --format='{{.Config.Image}}' "$container_id" 2>/dev/null || echo "")
    
    if echo "$image" | grep -qiE "php|laravel"; then
        return 0
    fi
    
    return 1
}

# ============================================
# Watch Loop
# ============================================

watch_docker_events() {
    log_info "Iniciando monitoramento de eventos Docker..."
    log_info "Aguardando containers Laravel iniciarem..."
    
    # Monitorar eventos de container
    docker events \
        --filter 'type=container' \
        --filter 'event=start' \
        --filter 'event=restart' \
        --format '{{.Actor.Attributes.name}}|{{.Action}}|{{.ID}}' 2>/dev/null | \
    while IFS='|' read -r container_name action container_id; do
        
        # Ignorar containers do próprio sistema
        if [[ "$container_name" =~ ^(aidev-|mcpx-|mcp-) ]]; then
            continue
        fi
        
        log_event "Container '$container_name' ($action)"
        
        # Verificar se é Laravel (debounce)
        if ! should_process_container "$container_name"; then
            log_info "  -> Ignorado (debounce ativo)"
            continue
        fi
        
        # Verificar se é container Laravel
        if is_laravel_container_by_id "$container_id"; then
            log_success "  -> Container Laravel detectado: $container_name"
            
            # Chamar trigger-orchestrator
            if [ -x "$SCRIPT_DIR/trigger-orchestrator.sh" ]; then
                "$SCRIPT_DIR/trigger-orchestrator.sh" trigger "$container_name" &
            else
                log_warn "  -> trigger-orchestrator.sh não encontrado"
            fi
        else
            log_info "  -> Não é container Laravel"
        fi
        
    done
}

# Modo foreground (para debug/teste)
watch_foreground() {
    log_info "Modo foreground (Ctrl+C para sair)..."
    watch_docker_events
}

# ============================================
# CLI
# ============================================

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  start                 Inicia watcher em background (daemon)
  stop                  Para o watcher
  status                Mostra status do watcher
  watch                 Roda em foreground (para debug)
  logs                  Mostra logs em tempo real
  tail [n]              Mostra últimas n linhas do log

Opções:
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 start              Inicia daemon
  $0 stop               Para daemon
  $0 status             Verifica status
  $0 watch              Roda em modo debug
  $0 logs               Acompanha logs

EOF
}

main() {
    local command="${1:-help}"
    
    case "$command" in
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon || true
            sleep 1
            start_daemon
            ;;
        status)
            status_daemon
            ;;
        watch|foreground)
            watch_foreground
            ;;
        logs|follow)
            ensure_state_dir
            tail -f "$EVENTS_LOG"
            ;;
        tail)
            local n="${2:-20}"
            if [ -f "$EVENTS_LOG" ]; then
                tail -n "$n" "$EVENTS_LOG"
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
