#!/bin/bash

# ============================================================================
# AI Dev Superpowers V3 - Context Git Module
# ============================================================================
# Mecanismo de micro-logs rotacionados por acao para sincronia em tempo real
# ============================================================================

CTXGIT_MAX_ENTRIES=${CTXGIT_MAX_ENTRIES:-50}
CTXGIT_ENABLED=${CTXGIT_ENABLED:-true}
CTXGIT_STORAGE=".aidev/state/context-log.json"

ctxgit_log() {
    local action="$1"
    local target="$2"
    local intent="$3"
    local task="${4:-}"
    local llm="${5:-gemini-cli}"
    
    [[ "$CTXGIT_ENABLED" != "true" ]] && return 0
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry=$(jq -n \
        --arg ts "$timestamp" \
        --arg action "$action" \
        --arg target "$target" \
        --arg intent "$intent" \
        --arg task "$task" \
        --arg llm "$llm" \
        '{ts: $ts, action: $action, target: $target, intent: $intent, sprint_task: $task, llm: $llm}')
    
    if [ ! -f "$CTXGIT_STORAGE" ]; then
        mkdir -p "$(dirname "$CTXGIT_STORAGE")"
        echo "{\"entries\": [$entry]}" > "$CTXGIT_STORAGE"
    else
        local tmp_file=$(mktemp)
        jq --argjson new_entry "$entry" '.entries += [$new_entry]' "$CTXGIT_STORAGE" > "$tmp_file" && mv "$tmp_file" "$CTXGIT_STORAGE"
    fi
    
    ctxgit_rotate
}

ctxgit_get_recent() {
    local limit="${1:-10}"
    [[ ! -f "$CTXGIT_STORAGE" ]] && return 0
    
    jq -c --argjson limit "$limit" '.entries | reverse | .[0:$limit | tonumber]' "$CTXGIT_STORAGE"
}

ctxgit_rotate() {
    [[ ! -f "$CTXGIT_STORAGE" ]] && return 0
    
    local count=$(jq '.entries | length' "$CTXGIT_STORAGE")
    if [ "$count" -gt "$CTXGIT_MAX_ENTRIES" ]; then
        local tmp_file=$(mktemp)
        local start_index=$(( count - CTXGIT_MAX_ENTRIES ))
        jq --argjson start "$start_index" '.entries = .entries[$start | tonumber:]' "$CTXGIT_STORAGE" > "$tmp_file" && mv "$tmp_file" "$CTXGIT_STORAGE"
    fi
}

ctxgit_render_timeline() {
    local limit="${1:-20}"
    local llm_filter="${2:-}"
    [[ ! -f "$CTXGIT_STORAGE" ]] && { echo "Nenhum log de contexto encontrado."; return 0; }
    
    local entries
    if [ -n "$llm_filter" ]; then
        entries=$(jq -c --arg llm "$llm_filter" '.entries | map(select(.llm == $llm))' "$CTXGIT_STORAGE")
    else
        entries=$(jq -c '.entries' "$CTXGIT_STORAGE")
    fi
    
    echo "$entries" | jq -r --argjson limit "$limit" 'reverse | .[0:$limit | tonumber] | .[] | "[\(.ts)] \(.llm): \(.action) -> \(.target) (\(.intent))"'
}

ctxgit_get_by_llm() {
    local llm="$1"
    local limit="${2:-10}"
    [[ ! -f "$CTXGIT_STORAGE" ]] && return 0
    
    jq -c --arg llm "$llm" --argjson limit "$limit" '.entries | map(select(.llm == $llm)) | reverse | .[0:$limit | tonumber]' "$CTXGIT_STORAGE"
}
