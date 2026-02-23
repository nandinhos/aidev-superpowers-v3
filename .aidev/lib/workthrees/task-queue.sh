#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"
QUEUE_FILE="$AIDEV_ROOT/state/workthrees/queue.json"
GRAPH_SCRIPT="$AIDEV_ROOT/lib/workthrees/dependency-graph.sh"

usage() {
    cat <<EOF
USAGE: task-queue.sh [COMMAND] [OPTIONS]

Gerencia fila de tarefas com prioridades e dependencias.

COMMANDS:
    enqueue     Adiciona tarefa a fila
    dequeue     Remove e retorna proxima tarefa executavel
    list        Lista todas as tarefas
    status      Mostra status de uma tarefa
    complete    Marca tarefa como concluida
    fail        Marca tarefa como falhou
    wait        Espera ate tarefa ficar executavel

OPTIONS:
    --task-id ID         ID da tarefa
    --priority N        Prioridade (1-10, default: 5)
    --depends-on IDS    IDs dependentes
    --description TEXT   Descricao da tarefa

EXEMPLOS:
    task-queue.sh enqueue --task-id "feat-001" --priority 5 --description "Nova feature"
    task-queue.sh dequeue
    task-queue.sh list
    task-queue.sh complete --task-id "feat-001"
EOF
    exit 1
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    enqueue|dequeue|list|status|complete|fail|wait) ;;
    *) usage ;;
esac

TASK_ID=""
PRIORITY=5
DEPENDS_ON=""
DESCRIPTION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-id) TASK_ID="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        --depends-on) DEPENDS_ON="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        *) shift ;;
    esac
done

init_queue() {
    if [[ ! -f "$QUEUE_FILE" ]]; then
        mkdir -p "$(dirname "$QUEUE_FILE")"
        cat > "$QUEUE_FILE" <<EOF
{
  "version": "1.0.0",
  "tasks": [],
  "created_at": "$(date -Iseconds)",
  "updated_at": "$(date -Iseconds)"
}
EOF
    fi
}

cmd_enqueue() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    if jq -e ".tasks[] | select(.id == \"$TASK_ID\")" "$QUEUE_FILE" >/dev/null 2>&1; then
        echo "ERROR: Tarefa $TASK_ID ja existe" >&2
        exit 1
    fi
    
    local deps_array="[]"
    if [[ -n "$DEPENDS_ON" ]]; then
        deps_array=$(echo "$DEPENDS_ON" | tr ',' '\n' | jq -R . | jq -s .)
    fi
    
    local escaped_desc=$(echo "$DESCRIPTION" | jq -Rs .)
    
    local task_json=$(cat <<EOF
{
  "id": "$TASK_ID",
  "depends_on": $deps_array,
  "priority": $PRIORITY,
  "status": "queued",
  "description": $escaped_desc,
  "created_at": "$(date -Iseconds)",
  "started_at": null,
  "completed_at": null
}
EOF
)
    
    local temp=$(mktemp)
    jq ".tasks += [$task_json] | .updated_at = \"$(date -Iseconds)\"" "$QUEUE_FILE" > "$temp" && mv "$temp" "$QUEUE_FILE"
    
    echo "OK: Tarefa $TASK_ID enfileirada (priority: $PRIORITY)"
}

cmd_dequeue() {
    init_queue
    
    local runnable=$($GRAPH_SCRIPT runnable 2>/dev/null || echo "[]")
    
    if [[ "$runnable" == "[]" ]] || [[ -z "$runnable" ]]; then
        echo "ERROR: Nenhuma tarefa executavel" >&2
        exit 1
    fi
    
    local task_id=$(echo "$runnable" | jq -r '.[0]')
    
    local temp=$(mktemp)
    jq ".tasks |= map(if .id == \"$task_id\" then .status = \"running\" | .started_at = \"$(date -Iseconds)\" else . end) | .updated_at = \"$(date -Iseconds)\"" "$QUEUE_FILE" > "$temp" && mv "$temp" "$QUEUE_FILE"
    
    jq -r ".tasks[] | select(.id == \"$task_id\")" "$QUEUE_FILE"
}

cmd_list() {
    init_queue
    
    local filter="${1:-all}"
    
    case "$filter" in
        queued|running|completed|failed)
            jq ".tasks[] | select(.status == \"$filter\")" "$QUEUE_FILE" 2>/dev/null || echo "[]"
            ;;
        *)
            jq '.tasks' "$QUEUE_FILE"
            ;;
    esac
}

cmd_status() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local task=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\")" "$QUEUE_FILE" 2>/dev/null || echo "null")
    
    if [[ "$task" == "null" ]]; then
        echo "ERROR: Tarefa $TASK_ID nao encontrada" >&2
        exit 1
    fi
    
    echo "$task"
}

cmd_complete() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local temp=$(mktemp)
    jq ".tasks |= map(if .id == \"$task_id\" then .status = \"completed\" | .completed_at = \"$(date -Iseconds)\" else . end) | .updated_at = \"$(date -Iseconds)\"" "$QUEUE_FILE" > "$temp" && mv "$temp" "$QUEUE_FILE"
    
    echo "OK: Tarefa $TASK_ID marcada como concluida"
}

cmd_fail() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local temp=$(mktemp)
    jq ".tasks |= map(if .id == \"$task_id\" then .status = \"failed\" | .completed_at = \"$(date -Iseconds)\" else . end) | .updated_at = \"$(date -Iseconds)\"" "$QUEUE_FILE" > "$temp" && mv "$temp" "$QUEUE_FILE"
    
    echo "OK: Tarefa $TASK_ID marcada como falhou"
}

cmd_wait() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local max_attempts=60
    local attempt=0
    
    while [[ $attempt -lt $max_attempts ]]; do
        local status=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .status" "$QUEUE_FILE" 2>/dev/null || echo "not_found")
        
        if [[ "$status" == "not_found" ]]; then
            echo "ERROR: Tarefa $TASK_ID nao encontrada" >&2
            exit 1
        fi
        
        if [[ "$status" == "queued" ]]; then
            local runnable=$($GRAPH_SCRIPT runnable 2>/dev/null || echo "[]")
            if echo "$runnable" | jq -e ". | index(\"$TASK_ID\")" >/dev/null 2>&1; then
                echo "OK: Tarefa $TASK_ID agora executavel"
                exit 0
            fi
        fi
        
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Timeout esperando tarefa $TASK_ID" >&2
    exit 1
}

case "$COMMAND" in
    enqueue) cmd_enqueue ;;
    dequeue) cmd_dequeue ;;
    list) cmd_list ;;
    status) cmd_status ;;
    complete) cmd_complete ;;
    fail) cmd_fail ;;
    wait) cmd_wait ;;
esac
