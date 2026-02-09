#!/usr/bin/env bash
#
# Trigger Orchestrator
# Coordena o fluxo: detecção -> health check -> configuração
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
readonly LIB_DIR="$MCP_DIR/lib"
readonly STATE_DIR="$MCP_DIR/state"
readonly ORCHESTRATOR_LOG="$STATE_DIR/orchestrator.log"

# Scripts dependentes
readonly DISCOVERY_SCRIPT="$LIB_DIR/docker-discovery.sh"
readonly HEALTH_SCRIPT="$LIB_DIR/laravel-health-check.sh"
readonly CONFIG_SCRIPT="$LIB_DIR/mcp-config-generator.sh"
readonly HOT_RELOAD_SCRIPT="$LIB_DIR/mcp-hot-reload.sh"

# Configurações
readonly MAX_RETRIES=5
readonly INITIAL_RETRY_DELAY=5
readonly MAX_RETRY_DELAY=60
readonly TOTAL_TIMEOUT=300  # 5 minutos

# Estados possíveis
readonly STATE_IDLE="IDLE"
readonly STATE_DETECTED="DETECTED"
readonly STATE_HEALTH_CHECKING="HEALTH_CHECKING"
readonly STATE_CONFIGURING="CONFIGURING"
readonly STATE_ACTIVE="ACTIVE"
readonly STATE_FAILED="FAILED"

# ============================================
# Logging
# ============================================

ensure_state_dir() {
    mkdir -p "$STATE_DIR"
    touch "$ORCHESTRATOR_LOG"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ORCHESTRATOR_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ORCHESTRATOR_LOG"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ORCHESTRATOR_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ORCHESTRATOR_LOG"
}

log_state() {
    local container="$1"
    local state="$2"
    echo -e "${CYAN}[STATE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $container: $state" | tee -a "$ORCHESTRATOR_LOG"
}

# ============================================
# State Machine
# ============================================

get_container_state_file() {
    local container_name="$1"
    echo "$STATE_DIR/${container_name}-state.json"
}

save_state() {
    local container_name="$1"
    local state="$2"
    local data="${3:-{}}"
    
    local state_file
    state_file=$(get_container_state_file "$container_name")
    
    cat > "$state_file" <<EOF
{
  "container": "$container_name",
  "state": "$state",
  "timestamp": "$(date -Iseconds)",
  "data": $data
}
EOF
    
    log_state "$container_name" "$state"
}

get_state() {
    local container_name="$1"
    local state_file
    state_file=$(get_container_state_file "$container_name")
    
    if [ -f "$state_file" ]; then
        jq -r '.state' "$state_file" 2>/dev/null || echo "$STATE_IDLE"
    else
        echo "$STATE_IDLE"
    fi
}

# ============================================
# Retry com Exponential Backoff
# ============================================

calculate_delay() {
    local attempt="$1"
    local delay=$((INITIAL_RETRY_DELAY * (2 ** (attempt - 1))))
    
    if [ "$delay" -gt "$MAX_RETRY_DELAY" ]; then
        delay=$MAX_RETRY_DELAY
    fi
    
    echo "$delay"
}

# ============================================
# Orchestration Steps
# ============================================

step_detect() {
    local container_name="$1"
    
    log_info "[$container_name] Executando detecção..."
    
    if [ ! -x "$DISCOVERY_SCRIPT" ]; then
        log_error "[$container_name] Script de discovery não encontrado"
        return 1
    fi
    
    # Atualizar estado
    save_state "$container_name" "$STATE_DETECTED"
    
    # Redescobrir containers
    "$DISCOVERY_SCRIPT" discover > /dev/null 2>&1
    
    # Verificar se container está na lista
    local container_info
    container_info=$("$DISCOVERY_SCRIPT" get "$container_name" 2>/dev/null || echo "")
    
    if [ -n "$container_info" ]; then
        log_success "[$container_name] Container detectado e validado"
        return 0
    else
        log_error "[$container_name] Container não encontrado na lista"
        return 1
    fi
}

step_health_check() {
    local container_name="$1"
    local attempt="$2"
    
    log_info "[$container_name] Health check (tentativa $attempt/$MAX_RETRIES)..."
    save_state "$container_name" "$STATE_HEALTH_CHECKING" "{\"attempt\": $attempt}"
    
    if [ ! -x "$HEALTH_SCRIPT" ]; then
        log_error "[$container_name] Script de health check não encontrado"
        return 1
    fi
    
    local health_result
    health_result=$("$HEALTH_SCRIPT" check "$container_name" --timeout 30 2>/dev/null || echo '{"status": "FAILED"}')
    
    local status
    status=$(echo "$health_result" | jq -r '.status' 2>/dev/null || echo "FAILED")
    
    case "$status" in
        "HEALTHY")
            log_success "[$container_name] Health check passou!"
            echo "$health_result" | jq -r '.elapsed_seconds'
            return 0
            ;;
        "PENDING")
            log_warn "[$container_name] Ainda inicializando..."
            return 2  # Código especial para retry
            ;;
        "FAILED")
            log_error "[$container_name] Health check falhou"
            return 1
            ;;
        *)
            log_error "[$container_name] Status desconhecido: $status"
            return 1
            ;;
    esac
}

step_configure() {
    local container_name="$1"
    
    log_info "[$container_name] Configurando MCP..."
    save_state "$container_name" "$STATE_CONFIGURING"
    
    if [ ! -x "$CONFIG_SCRIPT" ]; then
        log_error "[$container_name] Script de config não encontrado"
        return 1
    fi
    
    # Gerar e salvar configuração
    local config_file
    config_file=$("$CONFIG_SCRIPT" save "$container_name" 2>/dev/null || echo "")
    
    if [ -n "$config_file" ] && [ -f "$config_file" ]; then
        log_success "[$container_name] Configuração salva: $config_file"
        
        # Atualizar configuração combinada
        "$CONFIG_SCRIPT" merge > /dev/null 2>&1 || true
        
        return 0
    else
        log_error "[$container_name] Falha ao salvar configuração"
        return 1
    fi
}

step_activate() {
    local container_name="$1"

    log_info "[$container_name] Ativando..."

    # Hot-reload: aplicar config MCP ao IDE
    if [ -x "$HOT_RELOAD_SCRIPT" ]; then
        log_info "[$container_name] Aplicando hot-reload da configuracao MCP..."
        if "$HOT_RELOAD_SCRIPT" reload 2>/dev/null; then
            log_success "[$container_name] Hot-reload aplicado com sucesso"
        else
            log_warn "[$container_name] Hot-reload falhou (aplique manualmente com: aidev mcp laravel config reload)"
        fi
    fi

    save_state "$container_name" "$STATE_ACTIVE"

    log_success "[$container_name] Laravel Boost MCP ativo!"

    # Notificar (se houver sistema de notificacao)
    if command -v notify-send &> /dev/null; then
        notify-send "AI Dev Superpowers" "Laravel Boost MCP configurado para $container_name" 2>/dev/null || true
    fi
}

# ============================================
# Orchestration Flow
# ============================================

orchestrate_container() {
    local container_name="$1"
    local start_time
    start_time=$(date +%s)
    
    log_info "=========================================="
    log_info "Iniciando orquestração para: $container_name"
    log_info "=========================================="
    
    # Step 1: Detecção
    if ! step_detect "$container_name"; then
        save_state "$container_name" "$STATE_FAILED" '{"reason": "detection_failed"}'
        return 1
    fi
    
    # Step 2: Health Check (com retry)
    local attempt=1
    local health_passed=false
    
    while [ "$attempt" -le "$MAX_RETRIES" ]; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ "$elapsed" -ge "$TOTAL_TIMEOUT" ]; then
            log_error "[$container_name] Timeout total atingido (${TOTAL_TIMEOUT}s)"
            save_state "$container_name" "$STATE_FAILED" '{"reason": "timeout"}'
            return 1
        fi
        
        local health_result
        if step_health_check "$container_name" "$attempt"; then
            health_passed=true
            break
        else
            local exit_code=$?
            
            if [ "$exit_code" -eq 2 ] && [ "$attempt" -lt "$MAX_RETRIES" ]; then
                # PENDING - tentar novamente
                local delay
                delay=$(calculate_delay "$attempt")
                log_info "[$container_name] Aguardando ${delay}s antes da próxima tentativa..."
                sleep "$delay"
                ((attempt++))
            else
                # FAILED ou última tentativa
                log_error "[$container_name] Health check falhou após $attempt tentativa(s)"
                save_state "$container_name" "$STATE_FAILED" "{\"reason\": \"health_check_failed\", \"attempts\": $attempt}"
                return 1
            fi
        fi
    done
    
    if [ "$health_passed" = false ]; then
        log_error "[$container_name] Health check não passou"
        save_state "$container_name" "$STATE_FAILED" '{"reason": "health_check_not_passed"}'
        return 1
    fi
    
    # Step 3: Configuração
    if ! step_configure "$container_name"; then
        save_state "$container_name" "$STATE_FAILED" '{"reason": "configuration_failed"}'
        return 1
    fi
    
    # Step 4: Ativação
    step_activate "$container_name"
    
    local end_time
    end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    
    log_success "[$container_name] Orquestração completa em ${total_time}s"
    
    return 0
}

# ============================================
# CLI
# ============================================

list_active() {
    log_info "Containers ativos:"
    echo ""
    
    local found=false
    for state_file in "$STATE_DIR"/*-state.json; do
        [ -f "$state_file" ] || continue
        
        local container state timestamp
        container=$(jq -r '.container' "$state_file" 2>/dev/null || echo "")
        state=$(jq -r '.state' "$state_file" 2>/dev/null || echo "")
        timestamp=$(jq -r '.timestamp' "$state_file" 2>/dev/null || echo "")
        
        if [ -n "$container" ]; then
            found=true
            local status_icon="❓"
            case "$state" in
                "ACTIVE") status_icon="✅" ;;
                "FAILED") status_icon="❌" ;;
                "HEALTH_CHECKING") status_icon="🏥" ;;
                "CONFIGURING") status_icon="⚙️" ;;
                *) status_icon="⏳" ;;
            esac
            
            echo "  $status_icon $container | $state | $timestamp"
        fi
    done
    
    if [ "$found" = false ]; then
        echo "  Nenhum container processado ainda"
    fi
}

reset_container() {
    local container_name="$1"
    local state_file
    state_file=$(get_container_state_file "$container_name")
    
    if [ -f "$state_file" ]; then
        rm -f "$state_file"
        log_success "[$container_name] Estado resetado"
    else
        log_warn "[$container_name] Nenhum estado encontrado"
    fi
}

show_help() {
    cat <<EOF
Uso: $0 [COMANDO] [OPÇÕES]

Comandos:
  trigger <container>   Dispara orquestração para container
  list                  Lista containers ativos
  status <container>    Mostra estado de container específico
  reset <container>     Reseta estado de container
  logs                  Mostra logs do orchestrator

Opções:
  -h, --help            Mostra esta ajuda

Exemplos:
  $0 trigger my-app-php    Orquestra container
  $0 list                  Lista todos
  $0 status my-app-php     Ver estado
  $0 reset my-app-php      Resetar estado
  $0 logs                  Ver logs

EOF
}

main() {
    local command="${1:-help}"
    shift || true
    
    ensure_state_dir
    
    case "$command" in
        trigger|start|run)
            if [ -z "${1:-}" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            orchestrate_container "$1"
            ;;
        list|ls)
            list_active
            ;;
        status)
            if [ -z "${1:-}" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            local state
            state=$(get_state "$1")
            echo "$1: $state"
            ;;
        reset|clear)
            if [ -z "${1:-}" ]; then
                log_error "Nome do container não especificado"
                show_help
                exit 1
            fi
            reset_container "$1"
            ;;
        logs|log)
            if [ -f "$ORCHESTRATOR_LOG" ]; then
                tail -n 50 "$ORCHESTRATOR_LOG"
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
