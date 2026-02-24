#!/bin/bash
set -euo pipefail

AIDEV_ROOT="${AIDEV_ROOT:-.aidev}"
LOCKS_FILE="$AIDEV_ROOT/state/workthrees/locks.json"

usage() {
    cat <<EOF
USAGE: file-lock.sh [COMMAND] [OPTIONS]

Gerencia locks de arquivo para previnir conflitos em execucao paralela.

COMMANDS:
    acquire     Adquire lock em arquivos
    release     Libera lock
    check       Verifica se arquivos estao locked
    list        Lista locks ativos
    force-release  Force liberacao (admin)
    conflicts   Detecta conflitos potenciais

OPTIONS:
    --task-id ID         ID da tarefa (obrigatorio para acquire/release)
    --files FILE1,FILE2 Arquivos para lock (comma-separated)
    --wait              Espera ate lock ficar disponivel (default: nao espera)
    --timeout N         Timeout em segundos (default: 30)

EXEMPLOS:
    file-lock.sh acquire --task-id "feat-001" --files "src/auth/login.ts,src/auth/hooks.ts"
    file-lock.sh release --task-id "feat-001"
    file-lock.sh check --files "src/auth/login.ts"
    file-lock.sh conflicts --task-id "feat-001"
EOF
    exit 1
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
    acquire|release|check|list|force-release|conflicts) ;;
    *) usage ;;
esac

TASK_ID=""
FILES_INPUT=""
WAIT="false"
TIMEOUT=30

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-id) TASK_ID="$2"; shift 2 ;;
        --files) FILES_INPUT="$2"; shift 2 ;;
        --wait) WAIT="true"; shift ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

init_locks() {
    if [[ ! -f "$LOCKS_FILE" ]]; then
        mkdir -p "$(dirname "$LOCKS_FILE")"
        cat > "$LOCKS_FILE" <<EOF
{
  "version": "1.0.0",
  "locks": [],
  "created_at": "$(date -Iseconds)"
}
EOF
    fi
}

cleanup_expired_locks() {
    local max_age_seconds="${LOCK_TTL:-3600}"
    local now=$(date +%s)
    
    local temp=$(mktemp)
    local expired=0
    
    jq ".locks |= map(select(.acquired_at | fromdateiso8601) | .acquired_at | fromdateiso8601) | map(select(($now - (.acquired_at | fromdateiso8601)) < $max_age_seconds))" "$LOCKS_FILE" > "$temp" 2>/dev/null && mv "$temp" "$LOCKS_FILE" || true
}

cmd_acquire() {
    cleanup_expired_locks
    
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    if [[ -z "$FILES_INPUT" ]]; then
        echo "ERROR: --files e obrigatorio" >&2
        exit 1
    fi
    
    init_locks
    
    local files_array=$(echo "$FILES_INPUT" | tr ',' '\n' | jq -R . | jq -s .)
    
    local attempt=0
    while true; do
        local conflicts=$(cmd_check_raw "$FILES_INPUT")
        
        if [[ -z "$conflicts" ]] || [[ "$conflicts" == "[]" ]]; then
            local lock_json=$(cat <<EOF
{
  "task_id": "$TASK_ID",
  "files": $files_array,
  "acquired_at": "$(date -Iseconds)"
}
EOF
)
            
            local temp=$(mktemp)
            jq ".locks += [$lock_json]" "$LOCKS_FILE" > "$temp" && mv "$temp" "$LOCKS_FILE"
            
            echo "OK: Lock acquired para $TASK_ID em $FILES_INPUT"
            return 0
        fi
        
        if [[ "$WAIT" == "false" ]]; then
            echo "ERROR: Conflict detected, arquivos ja locked: $conflicts" >&2
            exit 1
        fi
        
        if [[ $attempt -ge $TIMEOUT ]]; then
            echo "ERROR: Timeout esperando lock" >&2
            exit 1
        fi
        
        echo "Aguardando lock... ($attempt/$TIMEOUT)"
        sleep 1
        attempt=$((attempt + 1))
    done
}

cmd_release() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_locks
    
    local lock_exists=$(jq ".locks[] | select(.task_id == \"$TASK_ID\")" "$LOCKS_FILE" 2>/dev/null || echo "null")
    
    if [[ "$lock_exists" == "null" ]]; then
        echo "WARNING: Nenhum lock encontrado para $TASK_ID"
        return 0
    fi
    
    local temp=$(mktemp)
    jq ".locks |= map(select(.task_id != \"$TASK_ID\"))" "$LOCKS_FILE" > "$temp" && mv "$temp" "$LOCKS_FILE"
    
    echo "OK: Lock released para $TASK_ID"
}

cmd_check_raw() {
    local files_to_check="$1"
    
    echo "$files_to_check" | tr ',' '\n' | while read -r file; do
        [[ -z "$file" ]] && continue
        jq -r ".locks[].files[]" "$LOCKS_FILE" 2>/dev/null | while read -r locked_file; do
            if [[ "$locked_file" == "$file" ]]; then
                echo "$file"
            fi
        done
    done | sort -u | jq -R . | jq -s .
}

cmd_check() {
    if [[ -z "$FILES_INPUT" ]]; then
        echo "ERROR: --files e obrigatorio" >&2
        exit 1
    fi
    
    init_locks
    
    local conflicts=$(cmd_check_raw "$FILES_INPUT")
    
    if [[ -z "$conflicts" ]] || [[ "$conflicts" == "[]" ]]; then
        echo "OK: Arquivos livres"
    else
        echo "LOCKED: $conflicts"
    fi
}

cmd_list() {
    init_locks
    jq '.locks' "$LOCKS_FILE"
}

cmd_force_release() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    init_locks
    
    local temp=$(mktemp)
    jq ".locks |= map(select(.task_id != \"$TASK_ID\"))" "$LOCKS_FILE" > "$temp" && mv "$temp" "$LOCKS_FILE"
    
    echo "OK: Lock forcado liberado para $TASK_ID"
}

cmd_conflicts() {
    if [[ -z "$TASK_ID" ]]; then
        echo "ERROR: --task-id e obrigatorio" >&2
        exit 1
    fi
    
    if [[ -z "$FILES_INPUT" ]]; then
        echo "ERROR: --files e obrigatorio" >&2
        exit 1
    fi
    
    init_locks
    
    local task_files=$(echo "$FILES_INPUT" | tr ',' '\n')
    
    local conflicts=()
    while read -r file; do
        [[ -z "$file" ]] && continue
        local locked_by=$(jq -r ".locks[] | select(.files | index(\"$file\")) | .task_id" "$LOCKS_FILE" 2>/dev/null || true)
        if [[ -n "$locked_by" && "$locked_by" != "$TASK_ID" ]]; then
            conflicts+=("{\"file\": \"$file\", \"locked_by\": \"$locked_by\"}")
        fi
    done <<< "$task_files"
    
    if [[ ${#conflicts[@]} -eq 0 ]]; then
        echo "[]"
    else
        printf '%s\n' "${conflicts[@]}" | jq -s .
    fi
}

case "$COMMAND" in
    acquire) cmd_acquire ;;
    release) cmd_release ;;
    check) cmd_check ;;
    list) cmd_list ;;
    force-release) cmd_force_release ;;
    conflicts) cmd_conflicts ;;
esac
