#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Sprint Manager Module
# ============================================================================
# Modulo para gerenciamento e integracao de sprints com o sistema de estado
#
# Uso: source .aidev/lib/sprint-manager.sh
# Dependencias: lib/core.sh
# ============================================================================

# Carrega dependencias
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/core.sh" ]; then
    source "$SCRIPT_DIR/core.sh"
elif [ -f "lib/core.sh" ]; then
    source lib/core.sh
fi

# ============================================================================
# FUNCOES PRINCIPAIS
# ============================================================================

# Retorna o caminho do arquivo sprint-status.json atual
# Uso: sprint_get_current [install_path]
# Retorna: path completo ou string vazia se nao existe
sprint_get_current() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file="$install_path/.aidev/state/sprints/current/sprint-status.json"

    if [ -f "$sprint_file" ]; then
        echo "$sprint_file"
    else
        echo ""
    fi
}

# Retorna o objeto overall_progress da sprint atual
# Uso: sprint_get_progress [install_path]
# Retorna: JSON do overall_progress ou string vazia
sprint_get_progress() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file=$(sprint_get_current "$install_path")

    if [ -z "$sprint_file" ]; then
        echo ""
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -c '.overall_progress' "$sprint_file" 2>/dev/null || echo ""
    else
        # Fallback sem jq
        grep -A 6 '"overall_progress"' "$sprint_file" | grep -v '^--$' || echo ""
    fi
}

# Retorna a proxima tarefa/acao da sprint
# Uso: sprint_get_next_task [install_path]
# Retorna: JSON do next_action ou string vazia
sprint_get_next_task() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file=$(sprint_get_current "$install_path")

    if [ -z "$sprint_file" ]; then
        echo ""
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        local next_action=$(jq -c '.next_action' "$sprint_file" 2>/dev/null)
        if [ "$next_action" = "null" ]; then
            echo ""
        else
            echo "$next_action"
        fi
    else
        # Fallback sem jq
        grep -A 5 '"next_action"' "$sprint_file" | grep -v '^--$' || echo ""
    fi
}

# Sincroniza dados da sprint para unified.json
# Uso: sprint_sync_to_unified [install_path]
sprint_sync_to_unified() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file=$(sprint_get_current "$install_path")
    local unified_file="$install_path/.aidev/state/unified.json"

    # Se nao ha sprint ativa, nao faz nada
    if [ -z "$sprint_file" ]; then
        return 0
    fi

    # Se unified.json nao existe, cria estrutura basica
    if [ ! -f "$unified_file" ]; then
        mkdir -p "$(dirname "$unified_file")"
        echo '{"version": "3.8.0", "session": {}}' > "$unified_file"
    fi

    # Verifica se jq esta disponivel
    if ! command -v jq >/dev/null 2>&1; then
        if command -v print_warning >/dev/null 2>&1; then
            print_warning "jq nao encontrado. Sincronizacao de sprint nao disponivel."
        fi
        return 1
    fi

    # Extrai campos essenciais do sprint-status.json
    local sprint_id=$(jq -r '.sprint_id' "$sprint_file")
    local sprint_name=$(jq -r '.sprint_name' "$sprint_file")
    local status=$(jq -r '.status' "$sprint_file")
    local completed=$(jq -r '.overall_progress.completed' "$sprint_file")
    local total=$(jq -r '.overall_progress.total_tasks' "$sprint_file")
    local current_task=$(jq -r '.current_task' "$sprint_file")

    # Calcula percentual de progresso
    local progress_pct=0
    if [ "$total" -gt 0 ]; then
        progress_pct=$(echo "scale=0; ($completed * 100) / $total" | bc 2>/dev/null || echo "0")
    fi

    # Extrai next_action
    local next_action_json=$(jq -c '.next_action // null' "$sprint_file")

    # Extrai session_context
    local checkpoints=$(jq -r '.session_context.checkpoints_created // 0' "$sprint_file")
    local sessions=$(jq -r '.session_context.sessions_count // 0' "$sprint_file")
    local tokens=$(jq -r '.session_context.tokens_used_in_sprint // 0' "$sprint_file")

    # Timestamp de sincronizacao
    local timestamp=$(date -Iseconds 2>/dev/null || date +"%Y-%m-%dT%H:%M:%S%z")

    # Cria objeto sprint_context
    local tmp_file=$(mktemp)
    jq --arg sprint_id "$sprint_id" \
       --arg sprint_name "$sprint_name" \
       --arg status "$status" \
       --argjson progress_pct "$progress_pct" \
       --argjson completed "$completed" \
       --argjson total "$total" \
       --arg current_task "$current_task" \
       --argjson next_action "$next_action_json" \
       --argjson checkpoints "$checkpoints" \
       --argjson sessions "$sessions" \
       --argjson tokens "$tokens" \
       --arg timestamp "$timestamp" \
       '.sprint_context = {
           "sprint_id": $sprint_id,
           "sprint_name": $sprint_name,
           "status": $status,
           "progress_percentage": $progress_pct,
           "completed_tasks": $completed,
           "total_tasks": $total,
           "current_task_id": (if $current_task == "null" then null else $current_task end),
           "next_action": $next_action,
           "session_metrics": {
               "checkpoints_created": $checkpoints,
               "sessions_count": $sessions,
               "tokens_used": $tokens
           },
           "last_sync": $timestamp
       }' "$unified_file" > "$tmp_file" && mv "$tmp_file" "$unified_file"
}

# Renderiza dashboard resumido da sprint atual
# Uso: sprint_render_summary [install_path]
sprint_render_summary() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file=$(sprint_get_current "$install_path")

    # Se nao ha sprint ativa, retorna vazio
    if [ -z "$sprint_file" ]; then
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Extrai dados
    local sprint_name=$(jq -r '.sprint_name' "$sprint_file")
    local status=$(jq -r '.status' "$sprint_file")
    local completed=$(jq -r '.overall_progress.completed' "$sprint_file")
    local total=$(jq -r '.overall_progress.total_tasks' "$sprint_file")

    # Calcula progresso
    local progress=0
    if [ "$total" -gt 0 ]; then
        progress=$(echo "scale=0; ($completed * 100) / $total" | bc 2>/dev/null || echo "0")
    fi

    # Renderiza header
    if command -v print_header >/dev/null 2>&1; then
        print_header "Sprint Atual: $sprint_name"
    else
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  Sprint Atual: $sprint_name"
        echo "╚════════════════════════════════════════════════════════════════╝"
    fi

    # Status com emoji
    local status_icon="⚪"
    case "$status" in
        "in_progress") status_icon="🟢" ;;
        "completed")   status_icon="✅" ;;
        "blocked")     status_icon="🚨" ;;
        "paused")      status_icon="⏸️ " ;;
    esac

    echo "  Status: $status_icon $status"

    # Barra de progresso
    echo -n "  Progresso: "
    if command -v print_progress >/dev/null 2>&1; then
        print_progress "$progress" 40 "full"
    else
        # Fallback simples
        echo "$progress%"
    fi

    echo "  Tarefas: $completed/$total concluídas"

    # Proxima acao
    local next_action=$(jq -r '.next_action.description // null' "$sprint_file")
    if [ "$next_action" != "null" ] && [ -n "$next_action" ]; then
        echo ""
        if command -v print_info >/dev/null 2>&1; then
            print_info "Próxima Ação: $next_action"
        else
            echo "  ℹ Próxima Ação: $next_action"
        fi
    fi
}

# ============================================================================
# FUNCOES AUXILIARES
# ============================================================================

# Valida se sprint-status.json tem estrutura correta
# Uso: sprint_validate [install_path]
# Retorna: 0 se valido, 1 se invalido
sprint_validate() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file=$(sprint_get_current "$install_path")

    if [ -z "$sprint_file" ]; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 0  # Sem jq, assume valido
    fi

    # Verifica campos obrigatorios
    local sprint_id=$(jq -r '.sprint_id' "$sprint_file" 2>/dev/null)
    local status=$(jq -r '.status' "$sprint_file" 2>/dev/null)
    local progress=$(jq -r '.overall_progress' "$sprint_file" 2>/dev/null)

    if [ "$sprint_id" = "null" ] || [ "$status" = "null" ] || [ "$progress" = "null" ]; then
        return 1
    fi

    return 0
}

# Retorna status da sprint atual (in_progress, completed, blocked, paused)
# Uso: sprint_get_status [install_path]
sprint_get_status() {
    local install_path="${1:-${CLI_INSTALL_PATH:-.}}"
    local sprint_file=$(sprint_get_current "$install_path")

    if [ -z "$sprint_file" ]; then
        echo ""
        return 1
    fi

    if command -v jq >/dev/null 2>&1; then
        jq -r '.status' "$sprint_file" 2>/dev/null || echo ""
    else
        grep -m 1 '"status"' "$sprint_file" | sed 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo ""
    fi
}
