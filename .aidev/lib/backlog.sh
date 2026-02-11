#!/bin/bash
# backlog.sh - Sistema de backlog de erros e tarefas pendentes
# Gerencia erros críticos que não podem ser perdidos

BACKLOG_FILE="${BACKLOG_FILE:-.aidev/state/backlog.json}"

# ============================================================================
# INICIALIZAÇÃO
# ============================================================================

backlog_init() {
    if [ ! -f "$BACKLOG_FILE" ]; then
        mkdir -p "$(dirname "$BACKLOG_FILE")"
        cat > "$BACKLOG_FILE" <<'EOF'
{
  "errors": [],
  "tasks": [],
  "last_updated": "",
  "metadata": {
    "version": "1.0",
    "total_resolved": 0,
    "total_open": 0
  }
}
EOF
    fi
}

# ============================================================================
# ERROS
# ============================================================================

backlog_add_error() {
    local title="$1"
    local description="$2"
    local severity="${3:-medium}"  # low, medium, high, critical
    local tags="${4:-[]}"
    local related_files="${5:-[]}"
    
    backlog_init
    
    local id="err-$(date +%s%N | cut -c1-12)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Valida severidade
    case "$severity" in
        low|medium|high|critical) ;;
        *) severity="medium" ;;
    esac
    
    local entry=$(jq -n \
        --arg id "$id" \
        --arg title "$title" \
        --arg description "$description" \
        --arg severity "$severity" \
        --argjson tags "$tags" \
        --argjson files "$related_files" \
        --arg created "$timestamp" \
        '{
            id: $id,
            type: "error",
            title: $title,
            description: $description,
            severity: $severity,
            status: "open",
            tags: $tags,
            related_files: $files,
            created_at: $created,
            updated_at: $created,
            resolved_at: null,
            resolution_notes: null,
            assignee: null
        }')
    
    _backlog_update "$entry"
    
    log_backlog "INFO" "backlog_add_error" "Erro adicionado: $id [$severity]"
    echo "$id"
}

backlog_resolve_error() {
    local error_id="$1"
    local resolution_notes="${2:-Resolvido}"
    local assignee="${3:-}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    backlog_init
    
    jq "
        .errors = [.errors[] | 
            if .id == \"$error_id\" then 
                .status = \"resolved\" | 
                .resolved_at = \"$timestamp\" | 
                .resolution_notes = \"$resolution_notes\" |
                .assignee = \"${assignee:-null}\" |
                .updated_at = \"$timestamp\"
            else . end
        ] |
        .metadata.total_resolved += 1
    " "$BACKLOG_FILE" > "${BACKLOG_FILE}.tmp" && mv "${BACKLOG_FILE}.tmp" "$BACKLOG_FILE"
    
    _backlog_update_metadata
    
    log_backlog "INFO" "backlog_resolve_error" "Erro resolvido: $error_id"
}

backlog_list_open_errors() {
    backlog_init
    jq '.errors | map(select(.status == "open")) | sort_by(
        if .severity == "critical" then 4
        elif .severity == "high" then 3
        elif .severity == "medium" then 2
        else 1 end
    ) | reverse' "$BACKLOG_FILE"
}

backlog_get_critical() {
    backlog_init
    jq '.errors | map(select(.severity == "critical" and .status == "open"))' "$BACKLOG_FILE"
}

backlog_get_by_tag() {
    local tag="$1"
    jq ".errors | map(select(.tags[] == \"$tag\" and .status == \"open\"))" "$BACKLOG_FILE"
}

# ============================================================================
# TAREFAS
# ============================================================================

backlog_add_task() {
    local title="$1"
    local description="$2"
    local priority="${3:-medium}"  # low, medium, high, urgent
    local estimated_minutes="${4:-30}"
    
    backlog_init
    
    local id="task-$(date +%s%N | cut -c1-12)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local entry=$(jq -n \
        --arg id "$id" \
        --arg title "$title" \
        --arg description "$description" \
        --arg priority "$priority" \
        --argjson estimated "$estimated_minutes" \
        --arg created "$timestamp" \
        '{
            id: $id,
            type: "task",
            title: $title,
            description: $description,
            priority: $priority,
            estimated_minutes: $estimated,
            status: "pending",
            created_at: $created,
            started_at: null,
            completed_at: null,
            assignee: null
        }')
    
    _backlog_update_task "$entry"
    
    log_backlog "INFO" "backlog_add_task" "Tarefa adicionada: $id [$priority]"
    echo "$id"
}

backlog_start_task() {
    local task_id="$1"
    local assignee="${2:-}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq "
        .tasks = [.tasks[] | 
            if .id == \"$task_id\" then 
                .status = \"in_progress\" | 
                .started_at = \"$timestamp\" |
                .assignee = \"${assignee:-null}\"
            else . end
        ]
    " "$BACKLOG_FILE" > "${BACKLOG_FILE}.tmp" && mv "${BACKLOG_FILE}.tmp" "$BACKLOG_FILE"
    
    log_backlog "INFO" "backlog_start_task" "Tarefa iniciada: $task_id"
}

backlog_complete_task() {
    local task_id="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq "
        .tasks = [.tasks[] | 
            if .id == \"$task_id\" then 
                .status = \"completed\" | 
                .completed_at = \"$timestamp\"
            else . end
        ]
    " "$BACKLOG_FILE" > "${BACKLOG_FILE}.tmp" && mv "${BACKLOG_FILE}.tmp" "$BACKLOG_FILE"
    
    log_backlog "INFO" "backlog_complete_task" "Tarefa concluída: $task_id"
}

backlog_list_pending_tasks() {
    backlog_init
    jq '.tasks | map(select(.status == "pending")) | sort_by(
        if .priority == "urgent" then 4
        elif .priority == "high" then 3
        elif .priority == "medium" then 2
        else 1 end
    ) | reverse' "$BACKLOG_FILE"
}

# ============================================================================
# ESTATÍSTICAS
# ============================================================================

backlog_stats() {
    backlog_init
    
    local total_errors=$(jq '.errors | length' "$BACKLOG_FILE")
    local open_errors=$(jq '.errors | map(select(.status == "open")) | length' "$BACKLOG_FILE")
    local critical=$(jq '.errors | map(select(.severity == "critical" and .status == "open")) | length' "$BACKLOG_FILE")
    local high=$(jq '.errors | map(select(.severity == "high" and .status == "open")) | length' "$BACKLOG_FILE")
    
    local total_tasks=$(jq '.tasks | length' "$BACKLOG_FILE")
    local pending_tasks=$(jq '.tasks | map(select(.status == "pending")) | length' "$BACKLOG_FILE")
    local in_progress=$(jq '.tasks | map(select(.status == "in_progress")) | length' "$BACKLOG_FILE")
    
    jq -n \
        --argjson total_errors "$total_errors" \
        --argjson open "$open_errors" \
        --argjson critical "$critical" \
        --argjson high "$high" \
        --argjson total_tasks "$total_tasks" \
        --argjson pending "$pending_tasks" \
        --argjson in_progress "$in_progress" \
        '{
            errors: {total: $total_errors, open: $open, critical: $critical, high_priority: $high},
            tasks: {total: $total_tasks, pending: $pending, in_progress: $in_progress}
        }'
}

backlog_show_dashboard() {
    backlog_init
    
    local stats=$(backlog_stats)
    
    echo "📊 DASHBOARD DE BACKLOG"
    echo "════════════════════════════════════════"
    echo ""
    echo "🐛 ERROS:"
    echo "  Abertos: $(echo "$stats" | jq -r '.errors.open')"
    echo "  Críticos: $(echo "$stats" | jq -r '.errors.critical')"
    echo "  Alta prioridade: $(echo "$stats" | jq -r '.errors.high_priority')"
    echo ""
    echo "📋 TAREFAS:"
    echo "  Pendentes: $(echo "$stats" | jq -r '.tasks.pending')"
    echo "  Em progresso: $(echo "$stats" | jq -r '.tasks.in_progress')"
    echo ""
    
    # Lista erros críticos
    local critical_errors=$(backlog_get_critical)
    local critical_count=$(echo "$critical_errors" | jq 'length')
    
    if [ "$critical_count" -gt 0 ]; then
        echo "🚨 ERROS CRÍTICOS ($critical_count):"
        echo "$critical_errors" | jq -r '.[] | "  • " + .id + ": " + .title'
        echo ""
    fi
    
    # Lista próximas tarefas
    local pending_tasks=$(backlog_list_pending_tasks | jq '.[0:3]')
    local pending_count=$(echo "$pending_tasks" | jq 'length')
    
    if [ "$pending_count" -gt 0 ]; then
        echo "⏭️  PRÓXIMAS TAREFAS:"
        echo "$pending_tasks" | jq -r '.[] | "  • [" + .priority + "] " + .id + ": " + .title'
    fi
}

# ============================================================================
# UTILITÁRIOS INTERNOS
# ============================================================================

_backlog_update() {
    local entry="$1"
    local temp_file="${BACKLOG_FILE}.tmp"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --argjson entry "$entry" --arg updated "$timestamp" \
        '.errors += [$entry] | .last_updated = $updated' \
        "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
    
    _backlog_update_metadata
}

_backlog_update_task() {
    local entry="$1"
    local temp_file="${BACKLOG_FILE}.tmp"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --argjson entry "$entry" --arg updated "$timestamp" \
        '.tasks += [$entry] | .last_updated = $updated' \
        "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
}

_backlog_update_metadata() {
    local temp_file="${BACKLOG_FILE}.tmp"
    
    jq '
        .metadata.total_open = (.errors | map(select(.status == "open")) | length)
    ' "$BACKLOG_FILE" > "$temp_file" && mv "$temp_file" "$BACKLOG_FILE"
}

log_backlog() {
    local level="$1"
    local function="$2"
    local message="$3"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [$level] [$function] $message" >&2
}

# ============================================================================
# CLI
# ============================================================================

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Foi sourced
    :
else
    echo "backlog.sh - Sistema de Backlog de Erros"
    echo ""
    echo "Funções disponíveis:"
    echo "  backlog_add_error <titulo> <descricao> [severity] [tags] [files]"
    echo "  backlog_resolve_error <id> [notas] [assignee]"
    echo "  backlog_list_open_errors"
    echo "  backlog_get_critical"
    echo "  backlog_add_task <titulo> <descricao> [priority] [estimated]"
    echo "  backlog_start_task <id> [assignee]"
    echo "  backlog_complete_task <id>"
    echo "  backlog_list_pending_tasks"
    echo "  backlog_stats"
    echo "  backlog_show_dashboard"
    echo ""
    backlog_show_dashboard
fi
