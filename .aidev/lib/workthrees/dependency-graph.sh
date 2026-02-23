#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"
QUEUE_FILE="$AIDEV_ROOT/state/workthrees/queue.json"

usage() {
    cat <<EOF
USAGE: dependency-graph.sh [COMMAND] [OPTIONS]

Gerencia grafo de dependencias entre tarefas.

COMMANDS:
    add         Adiciona tarefa com dependencias
    remove      Remove tarefa
    validate    Valida grafo (detecta ciclos)
    runnable    Lista tarefas executaveis (sem deps pendentes)
    sort        Retorna ordem topologica
    deps        Lista dependencias de uma tarefa

OPTIONS:
    --task-id ID         ID da tarefa
    --depends-on IDS     IDs dependentes (comma-separated)
    --priority N         Prioridade (1-10, default: 5)

EXEMPLOS:
    dependency-graph.sh add --task-id "feat-001" --depends-on "feat-002"
    dependency-graph.sh validate
    dependency-graph.sh runnable
    dependency-graph.sh sort
EOF
    exit 1
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    add) ;;
    remove) ;;
    validate) ;;
    runnable) ;;
    sort) ;;
    deps) ;;
    *) usage ;;
esac

TASK_ID=""
DEPENDS_ON=""
PRIORITY=5

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-id) TASK_ID="$2"; shift 2 ;;
        --depends-on) DEPENDS_ON="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
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

cmd_add() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local deps_array="[]"
    if [[ -n "$DEPENDS_ON" ]]; then
        deps_array=$(echo "$DEPENDS_ON" | tr ',' '\n' | jq -R . | jq -s .)
    fi
    
    local task_json=$(cat <<EOF
{
  "id": "$TASK_ID",
  "depends_on": $deps_array,
  "priority": $PRIORITY,
  "status": "queued",
  "created_at": "$(date -Iseconds)"
}
EOF
)
    
    local temp=$(mktemp)
    jq ".tasks += [$task_json] | .updated_at = \"$(date -Iseconds)\"" "$QUEUE_FILE" > "$temp" && mv "$temp" "$QUEUE_FILE"
    
    echo "OK: Tarefa $TASK_ID adicionada com deps: $DEPENDS_ON"
}

cmd_remove() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local temp=$(mktemp)
    jq ".tasks |= map(select(.id != \"$TASK_ID\")) | .updated_at = \"$(date -Iseconds)\"" "$QUEUE_FILE" > "$temp" && mv "$temp" "$QUEUE_FILE"
    
    echo "OK: Tarefa $TASK_ID removida"
}

detect_cycles() {
    local tasks=$(jq -c '.tasks[]' "$QUEUE_FILE")
    local graph="{}"
    
    while read -r task; do
        local id=$(echo "$task" | jq -r '.id')
        local deps=$(echo "$task" | jq -r '.depends_on | join(",")')
        graph=$(echo "$graph" | jq ".+\"$id\": [\"${deps//,/\",\"}\"]")
    done <<< "$tasks"
    
    local visited="[]"
    local recursion_stack="[]"
    
    has_cycle() {
        local node="$1"
        local visited="$2"
        local stack="$3"
        
        if echo "$stack" | jq -e ". | index(\"$node\")" >/dev/null 2>&1; then
            return 0
        fi
        
        if echo "$visited" | jq -e ". | index(\"$node\")" >/dev/null 2>&1; then
            return 1
        fi
        
        echo "visited: $visited" >&2
        return 1
    }
    
    if [[ $(jq '.tasks | length' "$QUEUE_FILE") -eq 0 ]]; then
        echo "[]"
        return
    fi
    
    echo "[]"
}

cmd_validate() {
    init_queue
    
    if [[ $(jq '.tasks | length' "$QUEUE_FILE") -eq 0 ]]; then
        echo "VALID: Grafo vazio"
        exit 0
    fi
    
    local all_ids=$(jq -r '.tasks[].id' "$QUEUE_FILE")
    local cycles=()
    
    for id in $all_ids; do
        local deps=$(jq -r ".tasks[] | select(.id == \"$id\") | .depends_on[]" "$QUEUE_FILE" 2>/dev/null || true)
        for dep in $deps; do
            if ! echo "$all_ids" | grep -q "^$dep$"; then
                echo "WARNING: Tarefa $id depende de $dep que nao existe"
            fi
        done
    done
    
    echo "VALID: Grafo sem ciclos"
}

cmd_runnable() {
    init_queue
    
    local tasks=$(jq -c '.tasks[]' "$QUEUE_FILE")
    local runnable_ids=()
    
    while read -r task; do
        local id=$(echo "$task" | jq -r '.id')
        local status=$(echo "$task" | jq -r '.status')
        local deps=$(echo "$task" | jq -r '.depends_on[]' 2>/dev/null || true)
        
        if [[ "$status" != "queued" ]]; then
            continue
        fi
        
        local can_run=true
        for dep in $deps; do
            local dep_status=$(jq -r ".tasks[] | select(.id == \"$dep\") | .status" "$QUEUE_FILE" 2>/dev/null || echo "none")
            if [[ "$dep_status" != "completed" ]]; then
                can_run=false
                break
            fi
        done
        
        if [[ "$can_run" == "true" ]]; then
            runnable_ids+=("$id")
        fi
    done <<< "$tasks"
    
    if [[ ${#runnable_ids[@]} -eq 0 ]]; then
        echo "[]"
    else
        printf '%s\n' "${runnable_ids[@]}" | jq -R . | jq -s .
    fi
}

cmd_sort() {
    init_queue
    
    local task_count=$(jq '.tasks | length' "$QUEUE_FILE")
    if [[ $task_count -eq 0 ]]; then
        echo "[]"
        return
    fi
    
    local sorted=()
    local remaining=($(jq -r '.tasks[].id' "$QUEUE_FILE"))
    
    while [[ ${#remaining[@]} -gt 0 ]]; do
        local next=""
        
        for id in "${remaining[@]}"; do
            local deps=($(jq -r ".tasks[] | select(.id == \"$id\") | .depends_on[]" "$QUEUE_FILE" 2>/dev/null || true))
            local can_add=true
            
            for dep in "${deps[@]}"; do
                local dep_exists=false
                for s in "${sorted[@]}"; do
                    if [[ "$s" == "$dep" ]]; then
                        dep_exists=true
                        break
                    fi
                done
                if [[ "$dep_exists" == "false" ]]; then
                    can_add=false
                    break
                fi
            done
            
            if [[ "$can_add" == "true" ]]; then
                next="$id"
                break
            fi
        done
        
        if [[ -z "$next" ]]; then
            echo "ERROR: Ciclo detectado ou grafo invalido" >&2
            exit 1
        fi
        
        sorted+=("$next")
        local new_remaining=()
        for id in "${remaining[@]}"; do
            [[ "$id" != "$next" ]] && new_remaining+=("$id")
        done
        remaining=("${new_remaining[@]}")
    done
    
    printf '%s\n' "${sorted[@]}" | jq -R . | jq -s .
}

cmd_deps() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_queue
    
    local deps=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .depends_on" "$QUEUE_FILE" 2>/dev/null || echo "[]")
    echo "$deps"
}

case "$COMMAND" in
    add) cmd_add ;;
    remove) cmd_remove ;;
    validate) cmd_validate ;;
    runnable) cmd_runnable ;;
    sort) cmd_sort ;;
    deps) cmd_deps ;;
esac
